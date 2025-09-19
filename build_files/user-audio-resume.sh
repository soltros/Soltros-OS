#!/usr/bin/env bash
set -euo pipefail
log(){ echo "=== $* ==="; }

# Install locations
install -d -m 755 /usr/libexec/soltros /usr/lib/systemd/user /etc/systemd/user/default.target.wants

# 1) Per-user resume listener (runs as the user, not root)
cat > /usr/libexec/soltros/soltros-user-resume-watcher.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
log(){ logger -t soltros-user-resume "$*"; }

restart_user_audio() {
  # brief delay so devices + session bus settle
  sleep 2
  systemctl --user restart pipewire.service 2>/dev/null || true
  systemctl --user restart wireplumber.service 2>/dev/null || true
  systemctl --user restart pipewire-pulse.service 2>/dev/null || true
  log "Restarted user audio stack after resume."
}

# Listen to logind's PrepareForSleep signal and trigger on resume (boolean false)
busctl monitor org.freedesktop.login1 \
| awk '/PrepareForSleep\(boolean/{ if ($0 ~ /false/) print "resume" }' \
| while read -r _; do restart_user_audio; done
EOF
chmod 755 /usr/libexec/soltros/soltros-user-resume-watcher.sh

# 2) User unit (lives in /usr/lib/systemd/user, runs in user scope)
cat > /usr/lib/systemd/user/soltros-user-resume-watcher.service <<'EOF'
[Unit]
Description=Soltros: restart PipeWire for this user after resume

[Service]
Type=simple
ExecStart=/usr/libexec/soltros/soltros-user-resume-watcher.sh
Restart=always
RestartSec=5s

[Install]
WantedBy=default.target
EOF

# 3) Enable for ALL users (present + future) without touching /etc/skel
ln -sf /usr/lib/systemd/user/soltros-user-resume-watcher.service \
       /etc/systemd/user/default.target.wants/soltros-user-resume-watcher.service

log "[OK] Installed global per-user resume watcher (no root --user calls)."

#!/usr/bin/env bash
set -euo pipefail

# 1) Drop the session script (runs in the user's KDE session)
install -d -m 755 /usr/libexec/soltros
cat > /usr/libexec/soltros/soltros-kde-pw-resume.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

DELAY="${SOLTROS_PW_RESUME_DELAY:-2}"

restart_user_audio() {
  sleep "$DELAY"
  systemctl --user restart pipewire.service 2>/dev/null || true
  systemctl --user restart wireplumber.service 2>/dev/null || true
  systemctl --user restart pipewire-pulse.service 2>/dev/null || true
  logger -t soltros-kde-pw-resume "Restarted PipeWire stack after resume."
}

# Listen for KDE PowerDevil's resume signal on the session bus
exec gdbus monitor --session \
  --dest org.kde.Solid.PowerManagement \
  --object-path /org/kde/Solid/PowerManagement/Actions/SuspendSession \
| while IFS= read -r line; do
    case "$line" in
      *"resumingFromSuspend("*")"*) restart_user_audio ;;
    esac
  done
EOF
chmod 755 /usr/libexec/soltros/soltros-kde-pw-resume.sh

# 2) Register it for ALL users via system-wide autostart (KDE only)
install -d -m 755 /etc/xdg/autostart
cat > /etc/xdg/autostart/soltros-kde-pw-resume.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Soltros: PipeWire Auto-Restart on Resume
Exec=/usr/libexec/soltros/soltros-kde-pw-resume.sh
OnlyShowIn=KDE;
X-KDE-autostart-phase=2
NoDisplay=true
EOF

#!/bin/bash
# SoltrOS Greetd Troubleshooting Script

echo "=== Greetd Status ==="
systemctl status greetd

echo -e "\n=== Greetd Configuration ==="
cat /etc/greetd/config.toml

echo -e "\n=== Available Sessions ==="
ls -la /usr/share/wayland-sessions/
ls -la /usr/share/xsessions/

echo -e "\n=== Greetd Logs ==="
journalctl -u greetd --no-pager -n 20

echo -e "\n=== Useful Commands ==="
echo "Restart greetd: sudo systemctl restart greetd"
echo "Check greetd config: sudo nano /etc/greetd/config.toml"
echo "Switch to TTY if needed: Ctrl+Alt+F2"

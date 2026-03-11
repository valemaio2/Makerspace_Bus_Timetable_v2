#!/bin/bash
set -e

PROJECT_DIR="/home/$USER/Makerspace_Bus_Timetable_v2"
SYSTEMD_USER_DIR="/home/$USER/.config/systemd/user"

echo "=== Makerspace Bus Timetable v2 Uninstaller ==="
echo "User: $USER"
echo "Project dir: $PROJECT_DIR"
echo

# Stop + disable user services/timers
echo "Stopping user-level systemd units..."

systemctl --user stop bus-scraper@${USER}.timer 2>/dev/null || true
systemctl --user stop light-control@${USER}.timer 2>/dev/null || true
systemctl --user stop busdisplay@${USER}.service 2>/dev/null || true

systemctl --user disable bus-scraper@${USER}.timer 2>/dev/null || true
systemctl --user disable light-control@${USER}.timer 2>/dev/null || true
systemctl --user disable busdisplay@${USER}.service 2>/dev/null || true

# Remove unit files
echo "Removing user-level systemd unit files..."

rm -f "$SYSTEMD_USER_DIR/bus-scraper@.service"
rm -f "$SYSTEMD_USER_DIR/bus-scraper@.timer"
rm -f "$SYSTEMD_USER_DIR/light-control@.service"
rm -f "$SYSTEMD_USER_DIR/light-control@.timer"
rm -f "$SYSTEMD_USER_DIR/busdisplay@.service"

systemctl --user daemon-reload || true

# Remove project dir
if [ -d "$PROJECT_DIR" ]; then
    echo "Removing project directory: $PROJECT_DIR"
    rm -rf "$PROJECT_DIR"
else
    echo "Project directory not found, skipping."
fi

echo
echo "=== Uninstallation complete ==="
echo "User-level services removed and project directory deleted."

#!/bin/bash
set -e

PROJECT_DIR="/home/$USER/Makerspace_Bus_Timetable_v2"
SYSTEMD_USER_DIR="/home/$USER/.config/systemd/user"

echo "=== Makerspace Bus Timetable v2 Uninstaller ==="

# ---------------------------------------------------------
# Stop + disable user services
# ---------------------------------------------------------
echo "Stopping user-level services..."

systemctl --user stop bus-scraper@${USER}.timer 2>/dev/null || true
systemctl --user stop light-control@${USER}.timer 2>/dev/null || true

systemctl --user disable bus-scraper@${USER}.timer 2>/dev/null || true
systemctl --user disable light-control@${USER}.timer 2>/dev/null || true

rm -f "$SYSTEMD_USER_DIR/bus-scraper@.service"
rm -f "$SYSTEMD_USER_DIR/bus-scraper@.timer"
rm -f "$SYSTEMD_USER_DIR/light-control@.service"
rm -f "$SYSTEMD_USER_DIR/light-control@.timer"

systemctl --user daemon-reload

# ---------------------------------------------------------
# Stop + disable system Chromium service
# ---------------------------------------------------------
echo "Removing system-level Chromium display service..."

sudo systemctl stop busdisplay.service 2>/dev/null || true
sudo systemctl disable busdisplay.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/busdisplay.service
sudo systemctl daemon-reload

# ---------------------------------------------------------
# Remove project directory
# ---------------------------------------------------------
if [ -d "$PROJECT_DIR" ]; then
    echo "Removing project directory..."
    rm -rf "$PROJECT_DIR"
fi

echo
echo "=== Uninstallation complete ==="
echo "All services removed and project directory deleted."

#!/bin/bash
set -e

PROJECT_DIR="/home/$USER/Makerspace_Bus_Timetable_v2"
SYSTEMD_USER_DIR="/home/$USER/.config/systemd/user"

echo "=== Makerspace Bus Timetable v2 Uninstaller ==="

# ---------------------------------------------------------
# Stop + disable USER-LEVEL services (scraper + light sensor + monitorctl)
# ---------------------------------------------------------
echo "Stopping user-level services..."

# Scraper
systemctl --user stop busdisplay-scraper.timer 2>/dev/null || true
systemctl --user disable busdisplay-scraper.timer 2>/dev/null || true
rm -f "$SYSTEMD_USER_DIR/busdisplay-scraper.service"
rm -f "$SYSTEMD_USER_DIR/busdisplay-scraper.timer"

# Light sensor
systemctl --user stop light-control@${USER}.timer 2>/dev/null || true
systemctl --user disable light-control@${USER}.timer 2>/dev/null || true
rm -f "$SYSTEMD_USER_DIR/light-control@.service"
rm -f "$SYSTEMD_USER_DIR/light-control@.timer"

# Monitor control (Wayland)
systemctl --user stop monitorctl@on.service 2>/dev/null || true
systemctl --user stop monitorctl@off.service 2>/dev/null || true
rm -f "$SYSTEMD_USER_DIR/monitorctl@.service"

systemctl --user daemon-reload

# ---------------------------------------------------------
# Stop + disable SYSTEM-LEVEL Chromium display service
# ---------------------------------------------------------
echo "Removing system-level Chromium display service..."

sudo systemctl stop busdisplay.service 2>/dev/null || true
sudo systemctl disable busdisplay.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/busdisplay.service
sudo systemctl daemon-reload

# ---------------------------------------------------------
# Remove monitor control script
# ---------------------------------------------------------
if [ -f "$PROJECT_DIR/monitorctl.sh" ]; then
    echo "Removing monitor control script..."
    rm -f "$PROJECT_DIR/monitorctl.sh"
fi

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
echo "Light sensor + monitor control fully removed."

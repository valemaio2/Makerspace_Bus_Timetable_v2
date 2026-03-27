#!/bin/bash
set -e

REPO_URL="https://github.com/valemaio2/Makerspace_Bus_Timetable_v2.git"
PROJECT_DIR="/home/$USER/Makerspace_Bus_Timetable_v2"
SYSTEMD_USER_DIR="/home/$USER/.config/systemd/user"

echo "=== Makerspace Bus Timetable v2 Installer ==="
echo "User: $USER"
echo "Project dir: $PROJECT_DIR"
echo

# ---------------------------------------------------------
# Clone or update repo
# ---------------------------------------------------------
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "Cloning repository..."
    git clone "$REPO_URL" "$PROJECT_DIR"
else
    echo "Repository exists. Pulling latest changes..."
    cd "$PROJECT_DIR"
    git pull
fi

cd "$PROJECT_DIR"

# ---------------------------------------------------------
# System packages
# ---------------------------------------------------------
echo "Installing system packages..."
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git chromium

# ---------------------------------------------------------
# Virtualenv
# ---------------------------------------------------------
if [ ! -d "$PROJECT_DIR/bin" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$PROJECT_DIR"
else
    echo "Virtual environment already exists."
fi

echo "Upgrading pip..."
$PROJECT_DIR/bin/pip3 install --upgrade pip

echo "Installing Python dependencies..."
$PROJECT_DIR/bin/pip3 install -r requirements.txt

mkdir -p "$PROJECT_DIR/log"

# Ensure scraper is executable
chmod +x "$PROJECT_DIR/scrape_buses.py"

# ---------------------------------------------------------
# Clean up old system-level scraper units (if any)
# ---------------------------------------------------------
echo "Removing old system-level scraper units..."
sudo rm -f /etc/systemd/system/busdisplay-scraper.service
sudo rm -f /etc/systemd/system/busdisplay-scraper.timer
sudo rm -f /etc/systemd/system/bus-scraper@.service
sudo rm -f /etc/systemd/system/bus-scraper@.timer
sudo systemctl daemon-reload

# ---------------------------------------------------------
# Install USER-LEVEL scraper service + timer
# ---------------------------------------------------------
echo "Installing user-level scraper units..."
mkdir -p "$SYSTEMD_USER_DIR"

# --- Service ---
cat > "$SYSTEMD_USER_DIR/busdisplay-scraper.service" <<EOF
[Unit]
Description=Generate buses.html

[Service]
Type=oneshot
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/bin/python3 $PROJECT_DIR/scrape_buses.py
EOF

# --- Timer ---
cat > "$SYSTEMD_USER_DIR/busdisplay-scraper.timer" <<EOF
[Unit]
Description=Run busdisplay-scraper.service every minute

[Timer]
OnBootSec=60
OnUnitActiveSec=60
AccuracySec=1s
Persistent=true

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now busdisplay-scraper.timer

# ---------------------------------------------------------
# Install system-level Chromium display service
# ---------------------------------------------------------
echo "Installing system-level Chromium display service..."

sudo tee /etc/systemd/system/busdisplay.service >/dev/null <<EOF
[Unit]
Description=Chromium fullscreen bus display
After=graphical.target

[Service]
User=$USER
Group=$USER
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/$USER/.Xauthority
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/chromium \
  --start-fullscreen \
  --noerrdialogs \
  --disable-infobars \
  --hide-crash-restore-bubble \
  --disable-background-timer-throttling \
  file://$PROJECT_DIR/buses.html
Restart=always

[Install]
WantedBy=graphical.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now busdisplay.service

# ---------------------------------------------------------
# Permissions
# ---------------------------------------------------------
sudo chown -R "$USER:$USER" "$PROJECT_DIR"

echo
echo "=== Installation complete ==="
echo "✔ Scraper running every minute as a USER service"
echo "✔ Chromium display running as a SYSTEM service"
echo "✔ Everything starts cleanly at boot"

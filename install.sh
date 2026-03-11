#!/bin/bash
set -e

REPO_URL="https://github.com/valemaio2/Makerspace_Bus_Timetable_v2.git"
PROJECT_DIR="/home/$USER/Makerspace_Bus_Timetable_v2"
VENV_DIR="$PROJECT_DIR"
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
if [ ! -d "$VENV_DIR/bin" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
else
    echo "Virtual environment already exists."
fi

echo "Upgrading pip..."
$VENV_DIR/bin/pip3 install --upgrade pip

echo "Installing Python dependencies..."
$VENV_DIR/bin/pip3 install -r requirements.txt

mkdir -p "$PROJECT_DIR/log"

# ---------------------------------------------------------
# Install user-level systemd units (scraper + light control)
# ---------------------------------------------------------
echo "Installing user-level systemd units..."
mkdir -p "$SYSTEMD_USER_DIR"

cp bus-scraper@.service "$SYSTEMD_USER_DIR/"
cp bus-scraper@.timer "$SYSTEMD_USER_DIR/"
cp light-control@.service "$SYSTEMD_USER_DIR/"
cp light-control@.timer "$SYSTEMD_USER_DIR/"

systemctl --user daemon-reload

echo "Enabling user timers..."
systemctl --user enable bus-scraper@${USER}.timer
systemctl --user enable light-control@${USER}.timer

systemctl --user start bus-scraper@${USER}.timer
systemctl --user start light-control@${USER}.timer

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
WorkingDirectory=/home/$USER/Makerspace_Bus_Timetable_v2
ExecStart=/usr/bin/chromium \
  --start-fullscreen \
  --noerrdialogs \
  --disable-infobars \
  --hide-crash-restore-bubble \
  file:///home/$USER/Makerspace_Bus_Timetable_v2/buses.html
Restart=always

[Install]
WantedBy=graphical.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable busdisplay.service
sudo systemctl restart busdisplay.service

# ---------------------------------------------------------
# Permissions
# ---------------------------------------------------------
sudo chown -R "$USER:$USER" "$PROJECT_DIR"

echo
echo "=== Installation complete ==="
echo "Scraper + light control running as user services."
echo "Chromium display running as a system service."
echo "Everything should now start cleanly at boot."

#!/bin/bash
set -e

REPO_URL="https://github.com/valemaio2/Makerspace_Bus_Timetable_v2.git"
PROJECT_DIR="/home/$USER/Makerspace_Bus_Timetable_v2"
VENV_DIR="$PROJECT_DIR"
PYTHON_BIN="$VENV_DIR/bin/python3"
PIP_BIN="$VENV_DIR/bin/pip3"
SYSTEMD_USER_DIR="/home/$USER/.config/systemd/user"

echo "=== Makerspace Bus Timetable v2 Installer ==="
echo "User: $USER"
echo "Project dir: $PROJECT_DIR"
echo

# Clone or update repo
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "Cloning repository..."
    git clone "$REPO_URL" "$PROJECT_DIR"
else
    echo "Repository exists. Pulling latest changes..."
    cd "$PROJECT_DIR"
    git pull
fi

cd "$PROJECT_DIR"

# System packages
echo "Installing system packages..."
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git chromium

# Virtualenv
if [ ! -d "$VENV_DIR/bin" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
else
    echo "Virtual environment already exists."
fi

# Pip + deps
echo "Upgrading pip..."
$PIP_BIN install --upgrade pip

echo "Installing Python dependencies..."
$PIP_BIN install -r requirements.txt

# Log dir
mkdir -p "$PROJECT_DIR/log"

# Systemd user units
echo "Installing user-level systemd units..."
mkdir -p "$SYSTEMD_USER_DIR"

cp bus-scraper@.service "$SYSTEMD_USER_DIR/"
cp bus-scraper@.timer "$SYSTEMD_USER_DIR/"
cp light-control@.service "$SYSTEMD_USER_DIR/"
cp light-control@.timer "$SYSTEMD_USER_DIR/"
cp busdisplay@.service "$SYSTEMD_USER_DIR/"

systemctl --user daemon-reload

# Enable linger so user services run at boot
echo "Enabling linger for $USER..."
sudo loginctl enable-linger "$USER"

# Enable + start units for this user
echo "Enabling and starting timers and services..."
systemctl --user enable bus-scraper@${USER}.timer
systemctl --user enable light-control@${USER}.timer
systemctl --user enable busdisplay@${USER}.service

systemctl --user start bus-scraper@${USER}.timer
systemctl --user start light-control@${USER}.timer
systemctl --user restart busdisplay@${USER}.service

# Permissions
sudo chown -R "$USER:$USER" "$PROJECT_DIR"

echo
echo "=== Installation complete ==="
echo "HTML: $PROJECT_DIR/buses.html"
echo "Systemd user units installed in: $SYSTEMD_USER_DIR"

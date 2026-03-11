#!/bin/bash
set -e

REPO_URL="https://github.com/valemaio2/Makerspace_Bus_Timetable_v2.git"
PROJECT_DIR="/home/$USER/Makerspace_Bus_Timetable_v2"
VENV_DIR="$PROJECT_DIR"
PYTHON_BIN="$VENV_DIR/bin/python3"
PIP_BIN="$VENV_DIR/bin/pip3"

echo "=== Makerspace Bus Timetable v2 Installer ==="
echo "Installing into: $PROJECT_DIR"
echo

# ---------------------------------------------------------
# Clone or update repository
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
# Install system dependencies
# ---------------------------------------------------------
echo "Installing system packages..."
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git chromium

# ---------------------------------------------------------
# Create virtual environment
# ---------------------------------------------------------
if [ ! -d "$VENV_DIR/bin" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
else
    echo "Virtual environment already exists."
fi

# ---------------------------------------------------------
# Upgrade pip
# ---------------------------------------------------------
echo "Upgrading pip..."
$PIP_BIN install --upgrade pip

# ---------------------------------------------------------
# Install Python dependencies
# ---------------------------------------------------------
echo "Installing Python dependencies..."
$PIP_BIN install -r requirements.txt

# ---------------------------------------------------------
# Create log directory
# ---------------------------------------------------------
mkdir -p "$PROJECT_DIR/log"

# ---------------------------------------------------------
# Install systemd templated services
# ---------------------------------------------------------
echo "Installing systemd services..."

sudo cp bus-scraper@.service /etc/systemd/system/
sudo cp bus-scraper@.timer /etc/systemd/system/
sudo cp light-control@.service /etc/systemd/system/
sudo cp light-control@.timer /etc/systemd/system/
sudo cp busdisplay@.service /etc/systemd/system/

sudo systemctl daemon-reload

# Enable timers and services for this user
sudo systemctl enable bus-scraper@${USER}.timer
sudo systemctl enable light-control@${USER}.timer
sudo systemctl enable busdisplay@${USER}.service

sudo systemctl start bus-scraper@${USER}.timer
sudo systemctl start light-control@${USER}.timer
sudo systemctl restart busdisplay@${USER}.service

# ---------------------------------------------------------
# Fix permissions
# ---------------------------------------------------------
sudo chown -R "$USER:$USER" "$PROJECT_DIR"

echo
echo "=== Installation complete! ==="
echo "Project installed at: $PROJECT_DIR"
echo "Services enabled for user: $USER"

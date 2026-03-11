#!/usr/bin/env python3
import json
import time
import subprocess
import os
import RPi.GPIO as GPIO

CONFIG_FILE = "light_config.json"
STATE_FILE = "/tmp/display_state.json"

LOG_DIR = "/home/$USER/Makerspace_Bus_Timetable_v2/log"
LOG_FILE = os.path.join(LOG_DIR, "light_control.log")


# ---------------------------------------------------------
# Load configuration
# ---------------------------------------------------------
def load_config():
    with open(CONFIG_FILE) as f:
        return json.load(f)


cfg = load_config()
PIN = cfg.get("pin", 4)
THRESHOLD = cfg.get("threshold", 2000)
TEST_MODE = cfg.get("test_mode", True)
DURATION = cfg.get("duration_seconds", 5)
LOGGING_ENABLED = cfg.get("logging_enabled", True)


# ---------------------------------------------------------
# Logging (toggleable)
# ---------------------------------------------------------
def log(msg):
    if not LOGGING_ENABLED:
        return

    os.makedirs(LOG_DIR, exist_ok=True)
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"{timestamp} {msg}\n")


# ---------------------------------------------------------
# Real sensor implementation (disabled unless TEST_MODE=False)
# ---------------------------------------------------------
def read_light_sensor_real():
    reading = 0

    GPIO.setmode(GPIO.BCM)

    GPIO.setup(PIN, GPIO.OUT)
    GPIO.output(PIN, GPIO.LOW)
    time.sleep(1)

    GPIO.setup(PIN, GPIO.IN)
    while GPIO.input(PIN) == GPIO.LOW:
        reading += 1

    GPIO.cleanup()
    return reading


# ---------------------------------------------------------
# Test-mode simulated sensor
# ---------------------------------------------------------
def read_light_sensor_test():
    return cfg.get("test_value", 2500)


# ---------------------------------------------------------
# Unified sensor read
# ---------------------------------------------------------
def read_light_sensor():
    if TEST_MODE:
        value = read_light_sensor_test()
        log(f"[TEST MODE] Simulated light reading: {value}")
        return value
    else:
        value = read_light_sensor_real()
        log(f"Real light reading: {value}")
        return value


# ---------------------------------------------------------
# Display control
# ---------------------------------------------------------
def set_display(on: bool):
    state = "on" if on else "off"
    log(f"Setting display: {state.upper()}")

    cmd = [
        "bash", "-c",
        f"WAYLAND_DISPLAY=wayland-0 wlopm --{state} HDMI-A-1"
    ]
    subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


# ---------------------------------------------------------
# State handling (prevents flicker)
# ---------------------------------------------------------
def load_last_state():
    if not os.path.exists(STATE_FILE):
        return None
    try:
        with open(STATE_FILE, "r") as f:
            return json.load(f).get("display_on")
    except:
        return None


def save_state(on: bool):
    with open(STATE_FILE, "w") as f:
        json.dump({"display_on": on}, f)


# ---------------------------------------------------------
# Main logic
# ---------------------------------------------------------
def main():
    brightness = read_light_sensor()
    log(f"Threshold: {THRESHOLD}, Brightness: {brightness}")

    display_should_be_on = brightness < THRESHOLD

    last_state = load_last_state()

    if last_state is None:
        log("No previous state found. Applying initial state.")
        set_display(display_should_be_on)
        save_state(display_should_be_on)
        return

    if display_should_be_on != last_state:
        log(f"State change: {last_state} → {display_should_be_on}")
        set_display(display_should_be_on)
        save_state(display_should_be_on)
    else:
        log("No change needed.")


if __name__ == "__main__":
    main()

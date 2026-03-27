import RPi.GPIO as GPIO
import time
import json
import subprocess
from pathlib import Path
import os

BASE_DIR = Path.home() / "Makerspace_Bus_Timetable_v2"
CONFIG_PATH = BASE_DIR / "light_config.json"
LOG_DIR = BASE_DIR / "log"
LOG_FILE = LOG_DIR / "light.log"

# Load config safely
with open(CONFIG_PATH) as f:
    cfg = json.load(f)

ENABLED = cfg.get("enabled", False)
PIN = cfg.get("pin", 4)
THRESHOLD = cfg.get("threshold", 2000)
DURATION = cfg.get("duration_seconds", 5)
TEST_MODE = cfg.get("test_mode", False)
TEST_VALUE = cfg.get("test_value", 200)
LOGGING_ENABLED = cfg.get("logging_enabled", True)

def log(msg):
    if not LOGGING_ENABLED:
        return
    os.makedirs(LOG_DIR, exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + msg + "\n")

def read_light_sensor(pin):
    """RC timing method: measure how long the capacitor takes to charge."""
    reading = 0

    GPIO.setup(pin, GPIO.OUT)
    GPIO.output(pin, GPIO.LOW)
    time.sleep(0.1)

    GPIO.setup(pin, GPIO.IN)

    while GPIO.input(pin) == GPIO.LOW:
        reading += 1

    return reading

def main():
    if not ENABLED:
        log("Light control disabled in config")
        return

    GPIO.setmode(GPIO.BCM)

    try:
        if TEST_MODE:
            value = TEST_VALUE
            log(f"[TEST MODE] Using test value: {value}")
        else:
            start = time.time()
            values = []

            while time.time() - start < DURATION:
                v = read_light_sensor(PIN)
                values.append(v)
                time.sleep(0.1)

            value = sum(values) // len(values)
            log(f"Light reading: {value}")

        if value < THRESHOLD:
            log("Bright → turning monitor ON")
            subprocess.run(["systemctl", "--user", "start", "monitorctl@on"])
        else:
            log("Dark → turning monitor OFF")
            subprocess.run(["systemctl", "--user", "start", "monitorctl@off"])

    finally:
        GPIO.cleanup()

if __name__ == "__main__":
    main()

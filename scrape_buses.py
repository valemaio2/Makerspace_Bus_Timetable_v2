import requests
from bs4 import BeautifulSoup
import json
from datetime import datetime


BASE_URL = "https://www.cardiffbus.com/stops/"

def scrape_train_station(code):
    url = f"https://www.realtimetrains.co.uk/search/simple/gb-nr:{code}"

    headers = {
        "User-Agent": "Mozilla/5.0"
    }

    r = requests.get(url, headers=headers, timeout=10)
    r.raise_for_status()

    soup = BeautifulSoup(r.text, "html.parser")

    services = soup.find_all("a", class_="service")

    departures = []

    for svc in services:
        # --- TIME ---
        time_el = svc.select_one(".time")
        raw_time = time_el.get_text(strip=True) if time_el else ""

        # Convert 4-digit time (e.g. 1045) → 10:45
        if len(raw_time) == 4 and raw_time.isdigit():
            formatted_time = raw_time[:2] + ":" + raw_time[2:]
        else:
            formatted_time = raw_time

        # --- DESTINATION ---
        dest = svc.select_one(".location span")
        destination = dest.get_text(strip=True) if dest else ""

        # --- STATUS (strip operator/coach info) ---
        addl = svc.select_one(".addl")
        secline = svc.select_one(".secline")

        status_text = ""
        if addl:
            status_text = addl.get_text(strip=True)
            if secline:
                status_text = status_text.replace(secline.get_text(strip=True), "").strip()

        # --- PLATFORM ---
        platform_el = svc.select_one(".platformbox")
        platform = platform_el.get_text(strip=True) if platform_el else ""

        departures.append({
            "time": formatted_time,
            "destination": destination,
            "status": status_text,
            "platform": platform
        })

    return departures

def scrape_stop(atco_code):
    url = BASE_URL + atco_code
    r = requests.get(url, timeout=10)
    r.raise_for_status()

    soup = BeautifulSoup(r.text, "html.parser")
    items = soup.select("li.departure-board__item")

    departures = []

    for item in items:
        line = item.select_one(".single-visit__name")
        dest = item.select_one(".single-visit__description")
        eta = item.select_one(".single-visit__arrival-time__cell")
        highlight = item.select_one(".single-visit__highlight")
        icon = item.select_one(".single-visit__icon__default")

        departures.append({
            "line": line.get_text(strip=True) if line else None,
            "destination": dest.get_text(strip=True) if dest else None,
            "eta": eta.get_text(strip=True) if eta else None,
            "colour": (
                highlight["style"]
                .replace("background-color:", "")
                .replace(";", "")
                .strip()
                if highlight else "#444"
            ),
            "live": (
                "real-time-animation" in icon.get("class", [])
                if icon else False
            )
        })

    return departures


def render_bus_row(dep):
    return f"""
    <tr>
      <td class="bus-line" style="background:{dep['colour']};">{dep['line']}</td>
      <td class="bus-destination">{dep['destination']}</td>
      <td class="bus-eta">{dep['eta']}</td>
    </tr>
    """


def render_bus_card(stop_name, departures):
    rows = "".join(render_bus_row(d) for d in departures)

    return f"""
    <div class="bus-card">
      <div class="bus-stop-title">{stop_name}</div>
      <table class="bus-table">
        {rows}
      </table>
    </div>
    """

def render_train_row(dep):
    return f"""
    <tr>
      <td class="train-time">{dep['time']}</td>
      <td class="train-destination">{dep['destination']}</td>
      <td class="train-status">{dep['status']}</td>
      <td class="train-platform">{dep['platform']}</td>
    </tr>
    """

def render_train_card(station_name, departures):
    rows = "".join(render_train_row(d) for d in departures)

    return f"""
    <div class="train-card">
      <div class="train-station-title">
        <img class="train-logo" src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/National_Rail_logo.svg/120px-National_Rail_logo.svg.png" alt="NR">
        {station_name}
      </div>
      <table class="train-table">
        {rows}
      </table>
    </div>
    """

def load_config():
    with open("config.json") as f:
        return json.load(f)

def main():
    cfg = load_config()
    stops = cfg["stops"]

    content = ""

    # -------------------------
    # BUS LOOP
    # -------------------------
    for stop_name, cfg_stop in stops.items():
        atco = cfg_stop["atco"]
        limit = cfg_stop["limit"]

        try:
            deps = scrape_stop(atco)

            if deps == []:
                title = stop_name.replace("_", " ").title()
                content += f"""
                <div class="bus-card">
                  <div class="bus-stop-title">{title}</div>
                  <p class="no-buses">No buses due</p>
                </div>
                """
                continue

            deps = deps[:limit]
            title = stop_name.replace("_", " ").title()
            content += render_bus_card(title, deps)

        except Exception:
            continue

    # -------------------------
    # TRAIN LOOP  (MOVED UP)
    # -------------------------
    for station_name, cfg_station in cfg["train_stations"].items():
        code = cfg_station["code"]
        limit = cfg_station["limit"]

        try:
            #print(f"Scraping trains for {station_name} ({code})…")
            deps = scrape_train_station(code)
            #print(" → Scraper returned:", len(deps))

            if deps == []:
                title = station_name.replace("_", " ").title()
                content += f"""
                <div class="train-card">
                  <div class="train-station-title">{title}</div>
                  <p class="no-buses">No trains due</p>
                </div>
                """
                continue

            deps = deps[:limit]
            title = station_name.replace("_", " ").title()
            content += render_train_card(title, deps)

        except Exception as e:
            print(f"Train station {station_name} ERROR — {e}")
            continue

    # -------------------------
    # NOW generate the HTML
    # -------------------------
    with open("template.html") as f:
        template = f.read()

    html = template.format(
        title="Bus Departures",
        heading="Live Bus & Train Departures",
        content=content,
        last_updated=datetime.now().strftime("%H:%M:%S")
    )

    with open("buses.html", "w") as f:
        f.write(html)

    print("Generated buses.html")

if __name__ == "__main__":
    main()

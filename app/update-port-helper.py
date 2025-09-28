#!/usr/bin/env python3
import os
import time
import requests
from datetime import datetime

# Environment variables with defaults
GLUETUN_URL = os.getenv("GLUETUN_URL", "http://gluetun:8000/v1/openvpn/portforwarded")
QBIT_URL = os.getenv("QBIT_URL", "http://qbittorrent:8080")
QBIT_USER = os.getenv("QBIT_USER", "admin")
QBIT_PASS = os.getenv("QBIT_PASS", "adminadmin")
INTERVAL_SECONDS = int(os.getenv("INTERVAL_SECONDS", "900"))

SESSION = requests.Session()

def log(message: str):
    print(f"{datetime.now().isoformat()} - {message}", flush=True)

def get_forwarded_port() -> int:
    try:
        resp = SESSION.get(GLUETUN_URL, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        return int(data.get("port", 0))
    except Exception as e:
        log(f"Failed to query Gluetun: {e}")
        return 0

def qbit_login() -> bool:
    try:
        resp = SESSION.post(
            f"{QBIT_URL}/api/v2/auth/login",
            data={"username": QBIT_USER, "password": QBIT_PASS},
            timeout=10,
        )
        # Successful login returns "Ok" or sets a cookie
        if resp.text.strip() == "Ok" or "SID" in SESSION.cookies.get_dict():
            return True
        return False
    except Exception as e:
        log(f"qBittorrent login failed: {e}")
        return False

def get_qbit_listen_port() -> int:
    try:
        resp = SESSION.get(f"{QBIT_URL}/api/v2/app/preferences", timeout=10)
        resp.raise_for_status()
        prefs = resp.json()
        return int(prefs.get("listen_port", 0))
    except Exception as e:
        log(f"Failed to get qBittorrent preferences: {e}")
        return 0

def set_qbit_listen_port(port: int) -> bool:
    try:
        payload = {"json": f'{{"listen_port":{port}}}'}
        resp = SESSION.post(f"{QBIT_URL}/api/v2/app/setPreferences", data=payload, timeout=10)
        if resp.status_code == 200:
            log(f"Updated qBittorrent listen_port => {port}")
            return True
        log(f"Failed to set qBittorrent port, status {resp.status_code}")
        return False
    except Exception as e:
        log(f"Error setting qBittorrent port: {e}")
        return False

def run_once():
    forwarded_port = get_forwarded_port()
    if forwarded_port <= 0:
        log("No forwarded port returned by Gluetun. Will retry later.")
        return

    if not get_qbit_listen_port():  # test API, might need login
        log("Not logged in to qBittorrent, attempting login...")
        if not qbit_login():
            log("qBittorrent login failed; check credentials and API availability.")
            return

    current_port = get_qbit_listen_port()
    if current_port == 0:
        log("Unable to determine current qBittorrent port.")
        return

    if current_port == forwarded_port:
        log(f"No change: qBittorrent port is already {current_port}")
        return

    log(f"Port change detected: qBittorrent={current_port} -> forwarded={forwarded_port}")
    set_qbit_listen_port(forwarded_port)

def main():
    while True:
        run_once()
        time.sleep(INTERVAL_SECONDS)

if __name__ == "__main__":
    main()

# 📡 Gluetun Port Updater

A lightweight Dockerized helper that keeps **qBittorrent’s listening port** in sync with the **forwarded port** assigned by [Gluetun VPN](https://github.com/qdm12/gluetun).

Some VPN providers (like ProtonVPN, PIA, etc.) assign a **random forwarded port** each time the VPN connects. Without syncing, qBittorrent can’t accept incoming peer connections, resulting in poor speeds.  

This container queries **Gluetun’s Control Server API** (`/v1/openvpn/portforwarded`) and updates qBittorrent automatically via its Web API.

---

## ✨ Features

- Queries Gluetun’s Control Server every **15 minutes** (configurable).  
- Detects if the forwarded port changes, updates qBittorrent automatically.  
- Small Alpine-based image (~7MB).  
- Configurable via environment variables.  
- Works with any Dockerized qBittorrent + Gluetun setup on the same network.  

---

## 🚀 Getting Started

### 1. Clone this repository
```bash
git clone https://github.com/<your-username>/gluetun-port-updater.git
cd gluetun-port-updater
```

### 2. Build the image
```bash
docker build -t gluetun-port-updater:latest -f images/gluetun-port-updater/Dockerfile .
```

### 3. Add service to `docker-compose.yml`
In the same Compose project where `gluetun` and `qbittorrent` run:

```yaml
  gluetun-port-updater:
    build:
      context: .
      dockerfile: images/gluetun-port-updater/Dockerfile
    image: gluetun-port-updater:latest
    container_name: gluetun-port-updater
    restart: unless-stopped
    depends_on:
      - gluetun
      - qbittorrent
    networks:
      - mediastack
    environment:
      GLUETUN_URL: "http://gluetun:8000/v1/openvpn/portforwarded"
      QBIT_URL: "http://qbittorrent:8080"
      QBIT_USER: "admin"
      QBIT_PASS: "adminadmin"
      INTERVAL_SECONDS: "900"
```

### 4. Start the container
```bash
docker compose up -d gluetun-port-updater
```

### 5. Check logs
```bash
docker logs -f gluetun-port-updater
```

Sample output:
```
2025-09-28T18:00:12+05:30 - Port change detected: qBittorrent=0 -> forwarded=49160
2025-09-28T18:00:13+05:30 - Updated qBittorrent listen_port => 49160
```

---

## ⚙️ Configuration

| Variable           | Default                                       | Description |
|--------------------|-----------------------------------------------|-------------|
| `GLUETUN_URL`      | `http://gluetun:8000/v1/openvpn/portforwarded` | Gluetun Control Server API endpoint. |
| `QBIT_URL`         | `http://qbittorrent:8080`                     | qBittorrent Web API URL. |
| `QBIT_USER`        | `admin`                                       | qBittorrent WebUI username. |
| `QBIT_PASS`        | `adminadmin`                                  | qBittorrent WebUI password. |
| `INTERVAL_SECONDS` | `900`                                         | Time between checks (seconds). |

---

## 🛠 How It Works

1. Queries Gluetun’s control server API for the current forwarded port.  
2. Logs into qBittorrent’s Web API with supplied credentials.  
3. Compares qBittorrent’s current listen port with the forwarded port.  
4. If different, updates qBittorrent preferences (`/api/v2/app/setPreferences`).  

---

## 🧪 Development

To run the script locally without Docker:
```bash
GLUETUN_URL="http://localhost:8000/v1/openvpn/portforwarded" QBIT_URL="http://localhost:8080" QBIT_USER="admin" QBIT_PASS="adminadmin" ./images/gluetun-port-updater/update-port.sh
```

---

## 📄 License

MIT License — feel free to fork, modify, and share.  
This project is community-maintained and not affiliated with qBittorrent, ProtonVPN, or Gluetun.

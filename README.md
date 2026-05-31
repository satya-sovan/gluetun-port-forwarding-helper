# 📡 Gluetun Port Updater

A lightweight Dockerized helper that keeps **qBittorrent’s listening port** in sync with the **forwarded port** assigned by [Gluetun VPN](https://github.com/qdm12/gluetun).

Some VPN providers (like ProtonVPN, PIA, etc.) assign a **random forwarded port** each time the VPN connects. Without syncing, qBittorrent can’t accept incoming peer connections, resulting in poor speeds.  

This container queries **Gluetun's Control Server API** (`/v1/portforward`) and updates qBittorrent automatically via its Web API.

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
      GLUETUN_URL: "http://gluetun:8000/v1/portforward"
      GLUETUN_USER: "gluetun-user"           # Required for Gluetun v3.39.1+
      GLUETUN_PASS: "gluetun-password"       # Required for Gluetun v3.39.1+
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
| `GLUETUN_URL`      | `http://gluetun:8000/v1/portforward` | Gluetun Control Server API endpoint. |
| `GLUETUN_USER`     | (optional)                                    | Gluetun API basic auth username. **Required for Gluetun v3.39.1+**. |
| `GLUETUN_PASS`     | (optional)                                    | Gluetun API basic auth password. **Required for Gluetun v3.39.1+**. |
| `QBIT_URL`         | `http://qbittorrent:8080`                     | qBittorrent Web API URL. |
| `QBIT_USER`        | `admin`                                       | qBittorrent WebUI username. |
| `QBIT_PASS`        | `adminadmin`                                  | qBittorrent WebUI password. |
| `INTERVAL_SECONDS` | `900`                                         | Time between checks (seconds). |

### 🔐 Gluetun API Authentication (v3.39.1+)

**Important:** Starting from Gluetun release **v3.39.1**, API authentication is **mandatory**.

You must:
1. **Configure authentication in Gluetun** - Set up basic auth credentials in your Gluetun container
2. **Provide credentials to this helper** - Set `GLUETUN_USER` and `GLUETUN_PASS` environment variables

**Example docker-compose.yml:**
```yaml
  gluetun:
    image: qmcgaw/gluetun:latest
    # ... other config ...
    environment:
      # Enable API auth and set credentials
      - HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE={"auth":"basic","username":"gluetun-user","password":"gluetun-password","routes":["GET /v1/portforward"]}
      

  gluetun-port-updater:
    # ... other config ...
    environment:
      GLUETUN_URL: "http://gluetun:8000/v1/portforward"
      GLUETUN_USER: "gluetun-user"
      GLUETUN_PASS: "gluetun-password"
      QBIT_URL: "http://qbittorrent:8080"
      QBIT_USER: "admin"
      QBIT_PASS: "adminadmin"
      INTERVAL_SECONDS: "900"
```

If you're using an older Gluetun version (< v3.39.1), the `GLUETUN_USER` and `GLUETUN_PASS` variables are optional.

More details on https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/control-server.md

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
GLUETUN_URL="http://gluetun:8000/v1/portforward" QBIT_URL="http://localhost:8080" QBIT_USER="admin" QBIT_PASS="adminadmin" ./images/gluetun-port-updater/update-port.sh
```

---

## 📄 License

MIT License — feel free to fork, modify, and share.  
This project is community-maintained and not affiliated with qBittorrent, ProtonVPN, or Gluetun.

# images/gluetun-port-updater/Dockerfile
FROM alpine:3.19

# install runtime deps
RUN apk add --no-cache curl jq tzdata

# create app dir
WORKDIR /app

# copy script
COPY update-port.sh /app/update-port.sh
RUN chmod +x /app/update-port.sh

# default envs (can be overridden via compose)
ENV GLUETUN_URL="http://gluetun:8000/v1/openvpn/portforwarded" \
    QBIT_URL="http://qbittorrent:8080" \
    QBIT_USER="admin" \
    QBIT_PASS="adminadmin" \
    INTERVAL_SECONDS=900

# entrypoint runs script in a loop (runs once immediately, then sleeps)
ENTRYPOINT ["/bin/sh", "-c", "/app/update-port.sh"]

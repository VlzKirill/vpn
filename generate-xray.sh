#!/bin/bash
set -e

DIR=./xray
mkdir -p $DIR

echo "[*] Generating Xray REALITY config..."

UUID=$(cat /proc/sys/kernel/random/uuid)

# --- ключи (ВАЖНО: сохраняем вывод полностью)
KEYS=$(docker run --rm ghcr.io/xtls/xray-core:latest x25519)

echo "$KEYS"

PRIVATE_KEY=$(echo "$KEYS" | grep "PrivateKey" | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEYS" | grep "PublicKey" | awk '{print $3}')

# проверка
if [ -z "$PRIVATE_KEY" ]; then
  echo "[!] ERROR: privateKey пустой"
  exit 1
fi

SHORT_ID=$(openssl rand -hex 8)
SERVER_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')

# --- config.json
cat <<EOF > $DIR/config.json
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "www.cloudflare.com:443",
          "serverNames": ["www.cloudflare.com"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["$SHORT_ID"]
        }
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom" }
  ]
}
EOF

# --- info.txt
cat <<EOF > $DIR/info.txt
====== Xray REALITY ======

UUID: $UUID
PublicKey: $PUBLIC_KEY
PrivateKey: $PRIVATE_KEY
ShortID: $SHORT_ID
SERVER_IP: $SERVER_IP

Connection string:

vless://$UUID@$SERVER_IP:443?encryption=none&security=reality&type=tcp&sni=www.cloudflare.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&flow=xtls-rprx-vision#xray

==========================
EOF

echo "[✔] DONE → $DIR/info.txt"
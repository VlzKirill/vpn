#!/bin/bash
set -e

CONF=/etc/ocserv/ocserv.conf

mkdir -p /etc/ocserv

# --- Генерация сертификата
if [ ! -f /etc/ocserv/server-cert.pem ]; then
  echo "[*] Generating self-signed cert..."

  certtool --generate-privkey --outfile /etc/ocserv/server-key.pem

cat << EOF > /etc/ocserv/server.tmpl
cn = sila4i.kz
organization = sila4i
expiration_days = 3650
signing_key
encryption_key
tls_www_server
EOF

  certtool --generate-self-signed \
    --load-privkey /etc/ocserv/server-key.pem \
    --template /etc/ocserv/server.tmpl \
    --outfile /etc/ocserv/server-cert.pem
fi

# --- Конфиг
if [ ! -f "$CONF" ]; then
cat << EOF > $CONF
auth = "plain[passwd=/etc/ocserv/ocpasswd]"

tcp-port = 443
udp-port = 443

run-as-user = nobody
run-as-group = nogroup

socket-file = /run/ocserv.sock

server-cert = /etc/ocserv/server-cert.pem
server-key = /etc/ocserv/server-key.pem

# --- Оптимизации ---
max-clients = 32
max-same-clients = 4

keepalive = 10
dpd = 30
mobile-dpd = 300

try-mtu-discovery = true

# важно для стабильности
switch-to-tcp-timeout = 5

# сеть
device = vpns
predictable-ips = true

ipv4-network = 10.10.10.0
ipv4-netmask = 255.255.255.0

dns = 1.1.1.1
dns = 8.8.8.8

tunnel-all-dns = true
#no-route = 5.39.253.179


# ускорение
cisco-client-compat = true
dtls-legacy = true

# безопасность (без фанатизма)
tls-priorities = "NORMAL:%SERVER_PRECEDENCE:-VERS-SSL3.0:-VERS-TLS1.0:-VERS-TLS1.1"

EOF
fi

# --- NAT (интернет через VPN)
iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "[*] Starting ocserv..."
exec ocserv -c /etc/ocserv/ocserv.conf -f

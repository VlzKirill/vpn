FROM debian:13.4

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    ocserv \
    gnutls-bin \
    iptables \
    iproute2 \
    ca-certificates \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/etc/ocserv"]

EXPOSE 443/tcp
EXPOSE 443/udp

ENTRYPOINT ["/entrypoint.sh"]

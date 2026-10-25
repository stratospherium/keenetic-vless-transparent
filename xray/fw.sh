#!/bin/sh
# VLESS transparent proxy firewall rules.
# Subnets listed in SEGS get their TCP redirected into xray; routing decision
# (proxy vs direct) is made by xray itself based on domain/IP rules.
#  - Example: segment B (192.168.2.0/24) goes fully through the tunnel (source rule in config.json)
#  - Example: segment A (192.168.1.0/24) is filtered by domains/IPs
CHAIN=vless_kvn
SRV=YOUR_SERVER_ADDRESS   # VPS hostname or IP — excluded from redirect so the tunnel itself doesn't loop
SEGS="192.168.2.0/24 192.168.1.0/24"

srv_ip() {
    nslookup $SRV 2>/dev/null | awk '/Address [0-9]+:/{print $3}' | grep -v ':' | head -1
}

start_rules() {
    iptables -t nat -N $CHAIN 2>/dev/null
    iptables -t nat -F $CHAIN
    for net in 0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4; do
        iptables -t nat -A $CHAIN -d $net -j RETURN
    done
    IP=$(srv_ip)
    if [ -n "$IP" ]; then
        iptables -t nat -A $CHAIN -d $IP -j RETURN
    fi
    iptables -t nat -A $CHAIN -p tcp -j REDIRECT --to-ports 1501
    for SRC in $SEGS; do
        iptables -t nat -C PREROUTING -s $SRC -j $CHAIN 2>/dev/null || iptables -t nat -A PREROUTING -s $SRC -j $CHAIN
        iptables -C FORWARD -s $SRC -p udp --dport 443 -j REJECT 2>/dev/null || iptables -I FORWARD -s $SRC -p udp --dport 443 -j REJECT
    done
}

stop_rules() {
    for SRC in $SEGS; do
        iptables -t nat -D PREROUTING -s $SRC -j $CHAIN 2>/dev/null
        iptables -D FORWARD -s $SRC -p udp --dport 443 -j REJECT 2>/dev/null
    done
    iptables -t nat -F $CHAIN 2>/dev/null
    iptables -t nat -X $CHAIN 2>/dev/null
}

case "$1" in
    start) start_rules ;;
    stop) stop_rules ;;
    *) echo "usage: $0 {start|stop}" ;;
esac

#!/bin/sh
# VLESS transparent proxy firewall rules:
#  - KVN segment (192.168.2.0/24): ALL tcp through xray
#  - Home segment (192.168.1.0/24): all tcp through xray, routing decided by xray
#  - DIRECT_NETS: bypass xray entirely (eXpress messenger must not use VPN)
CHAIN=vless_kvn
SRV=your-vps.example.com
SEGS="192.168.2.0/24 192.168.1.0/24"
DIRECT_NETS="198.51.100.10 198.51.100.11 198.51.100.12"

srv_ip() {
    nslookup $SRV 2>/dev/null | awk '/Address [0-9]+:/{print $3}' | grep -v ':' | head -1
}

start_rules() {
    iptables -t nat -N $CHAIN 2>/dev/null
    iptables -t nat -F $CHAIN
    for net in 0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4; do
        iptables -t nat -A $CHAIN -d $net -j RETURN
    done
    for net in $DIRECT_NETS; do
        iptables -t nat -A $CHAIN -d $net -j RETURN
    done
    IP=$(srv_ip)
    if [ -n "$IP" ]; then
        iptables -t nat -A $CHAIN -d $IP -j RETURN
    fi
    iptables -t nat -A $CHAIN -p tcp -j REDIRECT --to-ports 1501
    for SRC in $SEGS; do
        iptables -t nat -C PREROUTING -s $SRC -j $CHAIN 2>/dev/null || iptables -t nat -A PREROUTING -s $SRC -j $CHAIN
        for net in $DIRECT_NETS; do
            iptables -C FORWARD -s $SRC -d $net -p udp --dport 443 -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -s $SRC -d $net -p udp --dport 443 -j ACCEPT
        done
        iptables -C FORWARD -s $SRC -p udp --dport 443 -j REJECT 2>/dev/null || iptables -I FORWARD -s $SRC -p udp --dport 443 -j REJECT
    done
    iptables -C FORWARD -s 192.168.1.50 -p tcp --dport 853 -j REJECT 2>/dev/null || iptables -I FORWARD 1 -s 192.168.1.50 -p tcp --dport 853 -j REJECT
    ip6tables -I FORWARD 1 -s 192.168.1.0/24 -j REJECT 2>/dev/null
    ip6tables -I FORWARD 2 -s 192.168.2.0/24 -j REJECT 2>/dev/null
}

stop_rules() {
    for SRC in $SEGS; do
        iptables -t nat -D PREROUTING -s $SRC -j $CHAIN 2>/dev/null
        iptables -D FORWARD -s $SRC -p udp --dport 443 -j REJECT 2>/dev/null
        for net in $DIRECT_NETS; do
            iptables -D FORWARD -s $SRC -d $net -p udp --dport 443 -j ACCEPT 2>/dev/null
        done
    done
    iptables -D FORWARD -s 192.168.1.50 -p tcp --dport 853 -j REJECT 2>/dev/null
    ip6tables -D FORWARD -s 192.168.1.0/24 -j REJECT 2>/dev/null
    ip6tables -D FORWARD -s 192.168.2.0/24 -j REJECT 2>/dev/null
    iptables -t nat -F $CHAIN 2>/dev/null
    iptables -t nat -X $CHAIN 2>/dev/null
}

case "$1" in
    start) start_rules ;;
    stop) stop_rules ;;
    *) echo "usage: $0 {start|stop}" ;;
esac

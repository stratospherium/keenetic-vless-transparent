#!/bin/sh
# watchdog: if xray dies, remove fw rules (fail-open, direct traffic);
# if xray comes back, re-apply rules. Also re-apply if FORWARD rules vanish
# (Keenetic may purge foreign rules from FORWARD chain after Entware reinstall).
while true; do
    if pidof xray >/dev/null 2>&1; then
        NEED=0
        iptables -t nat -C PREROUTING -s 192.168.1.0/24 -j vless_kvn 2>/dev/null || NEED=1
        iptables -t nat -C PREROUTING -s 192.168.2.0/24 -j vless_kvn 2>/dev/null || NEED=1
        iptables -S FORWARD | grep -q 'dport 443' 2>/dev/null || NEED=1
        iptables -S FORWARD | grep -q 'dport 853' 2>/dev/null || NEED=1
        if [ "$NEED" = "1" ]; then
            /opt/etc/xray/fw.sh start
        fi
    else
        /opt/etc/xray/fw.sh stop 2>/dev/null
    fi
    sleep 60
done

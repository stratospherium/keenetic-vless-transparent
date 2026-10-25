#!/bin/sh
# watchdog: keep xray running and firewall rules in place.
# FAIL-SAFE: if xray is dead, REMOVE redirect rules so the network stays usable.
if pidof xray >/dev/null 2>&1; then
    /opt/etc/xray/fw.sh start
else
    /opt/etc/xray/fw.sh stop
    /opt/etc/init.d/S99vlessfw start >/dev/null 2>&1
    if pidof xray >/dev/null 2>&1; then
        /opt/etc/xray/fw.sh start
    else
        /opt/etc/xray/fw.sh stop
    fi
fi

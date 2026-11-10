#!/bin/sh
echo "$(date '+%F %T') scheduled xray restart" >> /opt/var/log/xray-restart.log
/opt/etc/init.d/S99vlessfw restart >> /opt/var/log/xray-restart.log 2>&1
echo "$(date '+%F %T') restart done, xray pid: $(pidof xray)" >> /opt/var/log/xray-restart.log

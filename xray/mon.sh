#!/bin/sh
# Tunnel speed sensor: measures download speed through the local socks inbound
# every 10 seconds and appends "<date> <bytes_per_sec>" to a log file.
# Start:  nohup sh /opt/etc/xray/mon.sh >/dev/null 2>&1 &
# Log:    /opt/var/log/tunnel-mon.log
while true; do
  S=$(curl -s -m 8 -x socks5h://127.0.0.1:1080 -o /dev/null -w '%{speed_download}' \
      'https://speed.cloudflare.com/__down?bytes=10000000')
  echo "$(date '+%F %T') $S" >> /opt/var/log/tunnel-mon.log
  sleep 10
done

#!/bin/sh
LOG=/opt/var/log/phone-mon.log
POS=1
if [ -f $LOG ] && [ $(wc -c < $LOG) -gt 20000000 ]; then mv $LOG $LOG.old; fi
echo "$(date '+%F %T') phone-monitor started" >> $LOG
while true; do
  T=$(date '+%F %T')
  P=$(ping -c 1 -W 1 192.168.1.50 >/dev/null 2>&1 && echo up || echo down)
  S=$(curl -s -o /dev/null -m 2 -w '%{speed_download}' --socks5-hostname 127.0.0.1:1080 'https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb' 2>/dev/null)
  NEW=$(tail -c +$POS /opt/var/log/xray-vless.log 2>/dev/null | grep -c 'from 192.168.1.50')
  DR=$(tail -c +$POS /opt/var/log/xray-vless.log 2>/dev/null | grep 'from 192.168.1.50' | grep -c '>> direct')
  SZ=$(wc -c < /opt/var/log/xray-vless.log 2>/dev/null)
  if [ -n "$SZ" ] && [ "$SZ" -gt 0 ]; then POS=$SZ; fi
  echo "$T phone=$P tunnel=$S new52conn=$NEW direct52=$DR" >> $LOG
  sleep 20
done

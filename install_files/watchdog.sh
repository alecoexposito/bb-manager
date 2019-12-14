#!/usr/bin/env bash

date
OUTPUT="$(qmicli -d /dev/cdc-wdm0 --nas-get-signal-strength)"
echo "${OUTPUT}"
STATUS="$(qmicli -d /dev/cdc-wdm0 --wds-get-packet-service-status)"
echo "${STATUS}"

if echo "$STATUS" | grep -q disconnected; then
  echo "Modem is disconnected";
  echo "Running ifdown wwan0"
  /sbin/ifdown wwan0
  sleep 1
  echo "Running ifup wwan0"
  /sbin/ifup wwan0
fi


PARAMS="{\"status\":\"$STATUS\"}"


curl -H 'Content-Type: application/json' -d "$PARAMS" http://189.213.227.211:3007/api/v1/modem-query &

ping -I wwan0 www.google.com -c 4

echo '******************************************************'

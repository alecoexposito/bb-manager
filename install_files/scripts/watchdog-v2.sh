#!/usr/bin/env bash


LOCK_FILE=/var/lock/bb-watchdog.lock
if test -f $LOCK_FILE; then
  exit
fi

echo "************ creando lock file /var/lock/bb-watchdog.lock ******************** "
echo 0 > /var/lock/bb-watchdog.lock

INFO = $(qmicli --device=/dev/cdc-wdm0 --nas-get-signal-info 2>&1)
RSSI=$(echo $INFO | sed -n "s/^.*RSSI:\s*\(\S*\).*$/\1/p")

echo $RSSI


rm $LOCK_FILE
echo "************ archivo lock /var/lock/bb-watchdog.lock eliminado ******************** "

echo '*********************************************************************************'
echo ''
echo ''
echo ''
echo ''
echo ''
echo ''
echo ''
echo ''

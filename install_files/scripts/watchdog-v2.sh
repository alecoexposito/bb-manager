#!/usr/bin/env bash

while [ True ]
do

# LOCK_FILE=/var/lock/bb-watchdog.lock
# if test -f $LOCK_FILE; then
#   exit
# fi

# echo "************ creando lock file /var/lock/bb-watchdog.lock ******************** "
# echo 0 > /var/lock/bb-watchdog.lock
LTE_MIN=-90
LTE_MAX=-50
INFO=$(qmicli --device=/dev/cdc-wdm0 --nas-get-signal-info 2>&1)
RSSI=$(echo $INFO | sed -n "s/^.*RSSI:\s'*\(\S*\).*$/\1/p")
echo "Respuesta: $INFO"
echo "RSSI: $RSSI"

if [[ $RSSI -lt $LTE_MIN ]]; then
  echo "esta por debajo de $LTE_MIN, sin internet"
  IS_DOWN="True"
  echo "corriendo ifdown"
  sudo ifdown wwan0
  echo "esperando 15 segundos"
  sleep 10
else
  if [ IS_DOWN == "True" ]; then
    IS_DOWN="False"
    sudo ifup wwan0
    echo "esperando 15 segundos"
    sleep 10
  fi
  echo "esta por encima de $LTE_MIN, con internet"
fi



# rm $LOCK_FILE
# echo "************ archivo lock /var/lock/bb-watchdog.lock eliminado ******************** "

echo '*********************************************************************************'
echo ''
echo ''

sleep 5
done
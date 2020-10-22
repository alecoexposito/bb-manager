#!/usr/bin/env bash
IS_DOWN="False"
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
  if [ $IS_DOWN == "False" ]; then
    IS_DOWN="True"
    echo "corriendo ifconfig wwan0 down"
    sudo /usr/sbin/ifconfig wwan0 down
    echo "esperando 7 segundos"
    /usr/bin/sleep 2
  fi
else
  if [ $IS_DOWN == "True" ]; then
    echo "bajando..."
    IS_DOWN="False"
    sudo /usr/bin/qmi-network /dev/cdc-wdm0 start
    /usr/bin/sleep 5
    sudo /usr/sbin/udhcpc -q -f -i wwan0
    echo "esperando 10 segundos"
    /usr/bin/sleep 5
  fi
  echo "esta por encima de $LTE_MIN, con internet"
fi


/usr/bin/sleep 5

# rm $LOCK_FILE
# echo "************ archivo lock /var/lock/bb-watchdog.lock eliminado ******************** "

echo '*********************************************************************************'
echo ''
echo ''

done
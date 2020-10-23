#!/usr/bin/env bash
IS_DOWN="False"
DOWN_COUNTER=0
UP_COUNTER=0

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

/bin/date
echo "up counter: $UP_COUNTER"
echo "down counter: $DOWN_COUNTER"

echo "gps info"
COORDS=$(/usr/bin/qmicli -p -d /dev/cdc-wdm0 --loc-get-position-report 2>&1 | head -n 30)
LAT=$(echo $COORDS | sed -n "s/^.*latitude:\s*\(\S*\).*$/\1/p")
LNG=$(echo $COORDS | sed -n "s/^.*longitude:\s*\(\S*\).*$/\1/p")
echo "$LAT, $LNG"

INFO=$(qmicli --device=/dev/cdc-wdm0 --nas-get-signal-info 2>&1)
NET=$(echo $INFO | sed -n "s/^.*:\s'*\(\S*\).*$/\1/p")

echo "red:  $NET"


echo "intensidad de la señal"
RSSI=$(echo $INFO | sed -n "s/^.*RSSI:\s'*\(\S*\).*$/\1/p")
echo "Respuesta: $INFO"
echo "RSSI: $RSSI"


if [[ $RSSI -lt $LTE_MIN ]]; then
  echo "esta por debajo de $LTE_MIN, sin internet"
  UP_COUNTER=0
  ((DOWN_COUNTER++))
  if [[ $DOWN_COUNTER -gt 3 ]]; then
      DOWN_COUNTER=0
      if [ $IS_DOWN == "False" ]; then
      IS_DOWN="True"
      sudo /usr/bin/qmi-network /dev/cdc-wdm0 stop
      echo "corriendo ifconfig wwan0 down"
      sudo /usr/sbin/ifconfig wwan0 down
      echo "esperando 7 segundos"
      /usr/bin/sleep 2
    fi
  fi
else
  DOWN_COUNTER=0
  ((UP_COUNTER++))
  if [[ UP_COUNTER -gt 3 ]]; then
    echo "subiendo red..."
    UP_COUNTER=0
    if [ $IS_DOWN == "True" ]; then
      IS_DOWN="False"
      sudo /usr/bin/qmi-network /dev/cdc-wdm0 start
      /usr/bin/sleep 5
      sudo /usr/sbin/udhcpc -q -f -i wwan0
      echo "esperando 10 segundos"
      /usr/bin/sleep 5
    fi
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
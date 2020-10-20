#!/usr/bin/env bash


LOCK_FILE=/var/lock/bb-watchdog.lock
if test -f $LOCK_FILE; then
  exit
fi

date

echo "************ creando lock file /var/lock/bb-watchdog.lock ******************** "
echo 0 > /var/lock/bb-watchdog.lock

echo "Hora Sistema"
date
# COORDS=$(qmicli -p -d /dev/cdc-wdm0 --loc-get-position-report 2>&1 | head -n 30)
# LAT=$(echo $COORDS | sed -n "s/^.*latitude:\s*\(\S*\).*$/\1/p")
# LNG=$(echo $COORDS | sed -n "s/^.*longitude:\s*\(\S*\).*$/\1/p")
# UTC_TIME=$(echo $COORDS | sed -n "s/^.*UTC timestamp:\s*\(\S*\).*$/\1/p")
# UTC_TIME=$((UTC_TIME / 1000))
# echo "Hora GPS"
# /bin/date -d @$UTC_TIME

# echo "************ coordenadas gps ************"
# echo "$LAT, $LNG"
date
sleep 1
echo "************ intensidad de la sennal ************"
date
qmicli -p -d /dev/cdc-wdm0 --nas-get-signal-strength 2>&1
date
sleep 1
echo "************ estado de la conexion ************"
date
# qmicli -p -d /dev/cdc-wdm0 --wds-get-packet-service-status 2>&1
STATUS="$(qmicli -p -d /dev/cdc-wdm0 --wds-get-packet-service-status)"
echo $STATUS
date
sleep 1
echo "************ ping to server *************"
date
ping -c 4 -I wwan0 69.64.32.172
date

IP='69.64.32.172'
MODEM_PORT='serial/by-id/usb-Android_Android-if02-port0'

if ! echo "$STATUS" | grep -q "Connection status: 'connected'";
then
  echo "Estado del modem no es connected";
  if ! echo "$STATUS" | grep -q "Connection status: 'disconnected'";
  then
    echo "el modem está en un estado bloqueado, reiniciando..."
    echo "comentado el reiniciar..... no hace nada"
    # echo "corriendo comando at AT+CFUN=1,1"
    # /usr/bin/python /home/zurikato/scripts/at-command.py AT+CFUN=1,1 $MODEM_PORT
    # sleep 10
    # echo "activando gps"
    # /usr/bin/python /home/zurikato/scripts/at-command.py AT+QGPS=1 $MODEM_PORT
    # sleep 3
  fi
  echo "corriendo el stop bajo protesta"
  /usr/local/bin/qmi-network-raw /dev/cdc-wdm0 stop
  sleep 3
  echo "Corriendo ifdown wwan0"
  /sbin/ifdown wwan0
  sleep 3
  echo "Corriendo ifup wwan0"
  /sbin/ifup wwan0
  sleep 3

else
  if ! ping -c 1 -I wwan0 $IP &> /dev/null
  then
    echo "Ping no responde"
    echo "corriendo el stop bajo protesta"
    /usr/local/bin/qmi-network-raw /dev/cdc-wdm0 stop
    sleep 3
    echo "Corriendo ifdown wwan0"
    /sbin/ifdown wwan0
    sleep 3
    echo "Corriendo ifup wwan0"
    /sbin/ifup wwan0
    sleep 3
  fi
fi

# IP='69.64.32.172'
# if ping -c 1 -I wwan0 $IP &> /dev/null
# then
#   echo "Conectado"
# else
#   echo "Desconectado, levantando la red de nuevo"
#   echo "Corriendo ifdown wwan0"
#   /sbin/ifdown wwan0
#   sleep 1
#   echo "Corriendo ifup wwan0"
#   /sbin/ifup wwan0
# fi

# OUTPUT="$(qmicli -d /dev/cdc-wdm0 --nas-get-signal-strength)"
# echo "${OUTPUT}"
# STATUS="$(qmicli -d /dev/cdc-wdm0 --wds-get-packet-service-status)"
# echo "${STATUS}"

# if echo "$STATUS" | grep -q disconnected; then
#   echo "Modem is disconnected";
#   echo "Running ifdown wwan0"
#   /sbin/ifdown wwan0
#   sleep 1
#   echo "Running ifup wwan0"
#   /sbin/ifup wwan0
# fi



# PARAMS="{\"status\":\"$STATUS\"}"


# curl -H 'Content-Type: application/json' -d "$PARAMS" http://189.213.227.211:3007/api/v1/modem-query &

# ping -I wwan0 www.google.com -c 4
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

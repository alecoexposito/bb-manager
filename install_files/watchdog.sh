#!/usr/bin/env bash

date

echo "************ coordenadas gps ************"
date
qmicli -d /dev/cdc-wdm0 --loc-get-position-report 2>&1 | head -n 3
date
sleep 1
echo "************ intensidad de la sennal ************"
date
qmicli -d /dev/cdc-wdm0 --nas-get-signal-strength 2>&1
date
sleep 1
echo "************ estado de la conexion ************"
date
qmicli -d /dev/cdc-wdm0 --wds-get-packet-service-status 2>&1
date
sleep 1
echo "************ ping to server *************"
date
ping -c 4 -I wwan0 69.64.32.172
date


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

echo '*********************************************************************************'

#!/usr/bin/env bash


/usr/bin/sleep 10
sudo /usr/bin/python /home/zurikato/scripts/at-command.py AT+QGPS=1 serial/by-id/usb-Android_Android-if02-port0 &
/usr/bin/sleep 20
# sudo /usr/bin/qmi-network /dev/cdc-wdm0 start
# /usr/bin/sleep 5
# sudo /usr/sbin/udhcpc -q -f -i wwan0 &
# /usr/bin/sleep 45
echo "iniciando el hotspot"
sudo ifdown --force ap0
sleep 8
sudo ip link set ap0 down
sleep 1
sudo ifup ap0
sleep 1
sudo /etc/init.d/hostapd restart
/usr/bin/sleep 10
sudo /usr/bin/bash /home/zurikato/scripts/watchdog-v2.sh >> /root/log/watchdog.log
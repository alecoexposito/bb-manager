#!/usr/bin/env bash


/usr/bin/sleep 10
sudo /usr/bin/python /home/zurikato/scripts/at-command.py AT+QGPS=1 serial/by-id/usb-Android_Android-if02-port0 &
/usr/bin/sleep 20
sudo /usr/bin/qmi-network /dev/cdc-wdm0 start
/usr/bin/sleep 5
sudo /usr/sbin/udhcpc -q -f -i wwan0
/usr/bin/sleep 90
sudo /usr/bin/bash /home/zurikato/scripts/watchdog-v2.sh >> /home/zurikato/logs/watchdog-v2.logs
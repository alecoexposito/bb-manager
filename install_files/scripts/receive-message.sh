#!/usr/bin/env bash

echo $1 >> /var/log/sms-received.log

echo $(whoami) >> /var/log/sms-received.log

#run this script only when a message was received.
if [ "$1" != "RECEIVED" ]; then exit; fi;

echo $2 >> /var/log/sms-received.log

#Extract data from the SMS file
#SENDER=`formail -zx From: &lt; $2`
#TEXT=`formail -I "" &lt;$2 | sed -e"1d"

#echo $SENDER >> /var/log/sms-received.log
#echo $text >> /var/log/sms-received.log

if fgrep -i 'RESTART' $2; then
  # echo "restarting" >> /var/log/sms-received.log
  sudo /sbin/reboot
fi

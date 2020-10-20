#!/usr/bin/env bash

while [True]
    do
        qmicli -p -d /dev/cdc-wdm0 --loc-get-position-report;    qmicli -p -d /dev/cdc-wdm0 --nas-get-signal-strength;    qmi-network /dev/cdc-wdm0 status;     ping -c 1 -I wwan0 69.64.32.172
        sleep 2
    done
#!/usr/bin/env python
"""Read button.

Make gpio input and enable pull-up resistor.
"""

import os
import sys
import time

from socketclusterclient import Socketcluster
import logging
import traceback

if not os.getegid() == 0:
    sys.exit('Script must be run as root')


from pyA20.gpio import gpio
from pyA20.gpio import connector
from pyA20.gpio import port

__author__ = "Stefan Mavrodiev"
__copyright__ = "Copyright 2014, Olimex LTD"
__credits__ = ["Stefan Mavrodiev"]
__license__ = "GPL"
__version__ = "2.0"
__maintainer__ = __author__
__email__ = "support@olimex.com"

logging.basicConfig(format='%(asctime)s - %(message)s', level=logging.INFO, filename='/var/log/panic-button.log')


#led = port.PA1    # This is the same as port.PH2
button = port.PA7 # #connector.gpio3p40
"""Init gpio module"""
gpio.init()

"""Set directions"""
#gpio.setcfg(led, gpio.OUTPUT)
gpio.setcfg(button, gpio.INPUT)

"""Enable pullup resistor"""
# gpio.pullup(button, gpio.PULLUP)
gpio.pullup(button, gpio.PULLDOWN)     # Optionally you can use pull-down resistor
error_sending = False;
def onconnect(socket):
    socket.subscribe('alarms_861585042256338')
    print("connected")
    logging.info("on connect got called")
    print ("Press CTRL+C to exit")
    last_seconds = 0
    is_pressed = False
    send_ping_to_server()
    counter = 0
    if error_sending == True:
        print ("error sending is true so I will send")
        send_panic_to_server()
    while True:
        # time.sleep(2)
        # continue
        counter = counter + 1
        state = gpio.input(button)      # Read button state
        print (state)
        logging.info(state)
        if state == 1:
            current_seconds = int(time.time())
            if is_pressed == False:
                last_seconds = current_seconds
                is_pressed = True
            elif (current_seconds - last_seconds) >= 2 and is_pressed == True:
                send_ping_to_server()
                send_panic_to_server()
                last_seconds = current_seconds
                is_pressed = False
                print("sending panic to server")
                logging.info("panic sent to server")
        else:
            is_pressed = False
            print ("counter: ", counter)
            if counter > 30:
                send_ping_to_server()
                counter = 0
        time.sleep(0.2)
        """Since we use pull-up the logic will be inverted"""
#        gpio.output(led, not state)


def ondisconnect(socket):
    print("disconnected")
    logging.info("on disconnect got called")


def onConnectError(socket, error):
    print("error on connect")
    logging.info("On connect error got called")

def init_socket():
    global socket
    socket = Socketcluster.socket("ws://69.64.32.172:3001/socketcluster/")
    socket.setBasicListener(onconnect, ondisconnect, onConnectError)
    socket.setdelay(2)
    socket.setreconnection(True)
    socket.connect()

def channelmessage(key, object):
    print ("Got data " + object + " from key " + key)

def send_panic_to_server():
    global socket
    print ("going to send")
    socket.publish('alarms_861585042256338', {'imei': '861585042256338'})
    print ("already sent")

def send_ping_to_server():
    global socket
    socket.publish('alarms_861585042256338', {'ping': '1'})
    socket.publish('alarms_861585042256338', {'ping': '1'})
    socket.publish('alarms_861585042256338', {'ping': '1'})
    print ("pings sent to server")

try:
    init_socket()

except KeyboardInterrupt:
    print ("Goodbye.")

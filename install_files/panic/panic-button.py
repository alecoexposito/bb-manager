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

logging.basicConfig(format='%(asctime)s - %(message)s', level=logging.INFO, filename='/var/log/panic-button.log')


#led = port.PA1    # This is the same as port.PH2
port = sys.argv[1] # debe ser 107
imei = str(sys.argv[2])
error_sending = False;
os.system("echo \"" + str(port) + "\" > /sys/class/gpio/export")
os.system("echo \"in\" > /sys/class/gpio/gpio" + str(port) + "/direction")
time.sleep(1)

def get_value():
  f = open("/sys/class/gpio/gpio" + str(port) + "/value")
  if f.mode == 'r':
    content = f.read()
    f.close()
    return content
  f.close()
  return -1

def onconnect(socket):
    socket.subscribe('alarms_' + str(imei))
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
        state = get_value()      # Read button state
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
    logging.info("going to send")
    socket.publish('alarms_' + str(imei), {'imei': str(imei)})
    print ("already sent")
    logging.info("already sent")

def send_ping_to_server():
    global socket
    socket.publish('alarms_' + str(imei), {'ping': '1'})
    socket.publish('alarms_' + str(imei), {'ping': '1'})
    socket.publish('alarms_' + str(imei), {'ping': '1'})
    print ("pings sent to server")
    logging.info("pings sent to server")

try:
  init_socket()

except KeyboardInterrupt:
    print ("Goodbye.")

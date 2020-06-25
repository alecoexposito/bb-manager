#!/usr/bin/env python

import os
import sys
import time

from socketclusterclient import Socketcluster
import logging

if not os.getegid() == 0:
    sys.exit('Script must be run as root')

logging.basicConfig(format='%(asctime)s - %(message)s', level=logging.INFO, filename='/var/log/restart-service.log')

def onconnect(socket):
    print("connected")  
    logging.info("connected")
    socket.subscribe('restart_611_channel')
    socket.onchannel('restart_611_channel', channelmessage)
#    socket.on('restart_611_channel', channelmessage)

def channelmessage(key, object):
    logging.info("restarting")
    os.system("/sbin/reboot")

def ondisconnect(socket):
    print("disconnected")
    logging.info("on disconnect got called")

def onConnectError(socket, error):
    print("error on connect")
    logging.info("On connect error got called")
    logging.error(error)

def init_socket():
    global socket
    socket = Socketcluster.socket("ws://69.64.32.172:3001/socketcluster/")
    socket.setBasicListener(onconnect, ondisconnect, onConnectError)
    socket.setdelay(2)
    socket.setreconnection(True)
    socket.enablelogger(True)
    socket.connect()

try:
    init_socket()

except KeyboardInterrupt:
    print ("Goodbye.")

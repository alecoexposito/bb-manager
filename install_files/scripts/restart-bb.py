#!/usr/bin/env python

import os
import sys
import time

from socketclusterclient import Socketcluster
import logging

if not os.getegid() == 0:
    sys.exit('Script must be run as root')

logging.basicConfig(format='%(asctime)s - %(message)s', level=logging.INFO, filename='/var/log/restart-service.log')

bb_id = str(sys.argv[1])
ip_server = str(sys.argv[2])

def onconnect(socket):
    print("connected")  
    logging.info("connected")
    socket.subscribe('restart_' + bb_id + '_channel')
    socket.onchannel('restart_' + bb_id + '_channel', channelmessage)

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
    socket = Socketcluster.socket("ws://" + str(ip_server) + ":3001/socketcluster/")
    socket.setBasicListener(onconnect, ondisconnect, onConnectError)
    socket.setdelay(2)
    socket.setreconnection(True)
    socket.enablelogger(True)
    socket.connect()

try:
    init_socket()

except KeyboardInterrupt:
    print ("Goodbye.")

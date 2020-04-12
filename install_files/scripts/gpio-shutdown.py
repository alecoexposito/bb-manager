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

logging.basicConfig(format='%(asctime)s - %(message)s', level=logging.INFO, filename='/var/log/gpio-poweroff.log')

port = str(sys.argv[1]) #debe ser 6
"""Init gpio module"""

error_sending = False;
f = open("/sys/class/gpio/gpio" + port + "/value")
def get_value(port):
  if f.mode == 'r':
    content = f.read()
    return content
  return -1

def shutdown():
  os.system("poweroff -f")

def init_gpio():
  os.system("echo \"" + port + "\" > /sys/class/gpio/export")
  os.system("echo \"in\" > /sys/class/gpio/gpio" + port + "/direction")
  while True:
        # time.sleep(2)
        # continue
        counter = counter + 1
        state = get_value(port)
        print (state)
        logging.info(state)
        if(state == -1):
          continue
        if state == "0":
            current_seconds = int(time.time())
            if is_pressed == False:
                last_seconds = current_seconds
                is_pressed = True
            elif (current_seconds - last_seconds) >= 2 and is_pressed == True:
                print("powering off...")
                logging.info("powering off...")
                last_seconds = current_seconds
                is_pressed = False
                shutdown()
        else:
            is_pressed = False
            print ("counter: ", counter)
            if counter > 30:
                send_ping_to_server()
                counter = 0
        time.sleep(0.2)
        """Since we use pull-up the logic will be inverted"""


try:
    init_gpio()

except KeyboardInterrupt:
    print ("Goodbye.")

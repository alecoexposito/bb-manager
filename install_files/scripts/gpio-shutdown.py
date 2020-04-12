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
def get_value():
  f = open("/sys/class/gpio/gpio" + str(port) + "/value")
  if f.mode == 'r':
    content = f.read()
    f.close()
    return content
  f.close()
  return -1

def shutdown():
  os.system("/sbin/poweroff -f")

def init_gpio():
  counter = 0
  os.system("echo \"" + port + "\" > /sys/class/gpio/export")
  os.system("echo \"in\" > /sys/class/gpio/gpio" + port + "/direction")
  while True:
        # time.sleep(2)
        # continue
        counter = counter + 1
        state = get_value()
        print (state)
        logging.info(state)
        if(state == -1):
          continue
        if state == "0\n":
                print("powering off...")
                logging.info("powering off...")
                shutdown()
        time.sleep(0.2)
        """Since we use pull-up the logic will be inverted"""


try:
    init_gpio()

except KeyboardInterrupt:
    print ("Goodbye.")

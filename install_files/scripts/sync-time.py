import subprocess
import re
import os

result = subprocess.run(['/usr/bin/qmicli', '-d', '/dev/cdc-wdm0', '--dms-get-time'], stdout=subprocess.PIPE)

text = result.stdout.decode('utf-8')

#'System time: \'1270223656846 (ms)'

# text = "[/dev/cdc-wdm0] Time retrieved:\n\tTime count: '1016190310123 (x 1.25ms): 2012-03-19 11:05:10'\n\tTime source: 'device'\n\tSystem time: '1270237887654 (ms): 2020-04-06 19:51:27'\n\tUser time: '17227186 (ms): 1980-01-06 04:47:07'"

text = re.split("\n\t", text)[3]
m = re.match("^System\stime:\s\'\d+\s\(ms\):\s(\d+-\d+-\d+\s\d+:\d+:\d+)", text)
print(text)
print(m.groups())
if m:
    # print(m.groups())
    # exit(0)
    # miliStr = m.groups()[0]
    # milliseconds = int(miliStr)
    # milliseconds = int(milliseconds)
    new_date = m.groups()[0]
    os.system("/bin/date -s \'" + new_date + "UTC\'")

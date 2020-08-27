import http.client
import json
import os
import sys

# config = loadConfiguration()

def loadConfiguration():
    return []

def getPath():
    conn = http.client.HTTPConnection('69.64.32.172',  3010)
    id = sys.argv[1]
    conn.request('GET', '/blackboxes/' + id + '/getPath')
    resp = conn.getresponse()
    responseStr = resp.read().decode()
    if resp.status == 200:
        data = json.loads(responseStr)
        awsFolder = data['path']
        return awsFolder
    else:
        return ''

def updateSettingsFile():
    conn = http.client.HTTPConnection('69.64.32.172',  3010)
    id = sys.argv[1]
    conn.request('GET', '/blackboxes/' + id + '/getSettings')
    resp = conn.getresponse()
    responseStr = resp.read().decode()
    if is_json(responseStr):
        f = open('/home/zurikato/apps/tvz-media-server/settings-bb.json', 'w')
        f.write(responseStr)
        return responseStr
    return ''

def is_json(str):
  try:
    json_object = json.loads(str)
  except ValueError as e:
    return False
  return True



path = getPath()
settingsStr = updateSettingsFile()
settingsDict = json.loads(settingsStr)
print(settingsDict)
if settingsDict['deleteOnSync']:
    print('se puede borrar en el sync')
    os.system("/usr/bin/aws s3 sync s3://" + path + " /home/zurikato/apps/tvz-media-server/media --size-only --delete --exclude \"*local-*.*\"")

else:
    print('no se puede borrar en el sync')
    os.system("/usr/bin/aws s3 sync s3://" + path + " /home/zurikato/apps/tvz-media-server/media --size-only --exclude \"*local-*.*\"")

# os.system("/usr/bin/aws s3 sync s3://" + path + " /home/zurikato/apps/tvz-media-server/media --size-only --delete --exclude \"*local-*.*\"")
# os.system("cd /home/zurikato/apps/tvz-media-server/media; /usr/bin/find $PWD -regex '.*\.\(mkv\|webm\|avi\|mp4\)$' | while read f; do /usr/bin/ffmpeg -n -i \"$f\" -ss 00:00:03 -vframes 1 -s 480x320 ${f%/*}/thumb-\"${f##*/}\".jpg; done")




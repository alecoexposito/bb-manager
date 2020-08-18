import http.client
import json
import os
import sys

# config = loadConfiguration()

def loadConfiguration():
    return []

def getPath():
    print("en el metodo")
    conn = http.client.HTTPConnection('69.64.32.172',  3010)
    id = sys.argv[1]
    conn.request('GET', '/blackboxes/' + id + '/getPath')
    resp = conn.getresponse()
    responseStr = resp.read().decode();
    print("resp: ", responseStr)
    if resp.status == 200:
        data = json.loads(responseStr)
        print(data)
        awsFolder = data['path']
        return awsFolder
    else:
        return ''

print("llamando  al metodo")
path = getPath()
print(path);

# /usr/local/bin/aws s3 sync s3://zurikato-dev-01/1 /home/zurikato/tmp/1 --size-only --delete

os.system("/usr/bin/aws s3 sync s3://" + path + " /home/zurikato/apps/tvz-media-server/media --size-only --delete --exclude \"*local-*.*\"")
os.system("cd /home/zurikato/apps/tvz-media-server/media; for f in $(find $PWD -regex '.*\.\(mkv\|webm\|avi\|mp4\)$'); do /usr/bin/ffmpeg -n -i $f -ss 00:00:03 -vframes 1 -s 480x320 ${f%/*}/thumb-${f##*/}.jpg; done")

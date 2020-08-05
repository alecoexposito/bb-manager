#!/usr/bin/env bash

# while ! /bin/mount | /usr/bin/awk '{print $3}' | /bin/grep -qx /home/zurikato/video-backup; do
#     echo 'not mounted, waiting'
#     /bin/sleep 1
# done

if [[ ! -d "/home/zurikato/video-backup/$1" ]]
then
    mkdir "/home/zurikato/video-backup/$1"
fi


/usr/bin/ffmpeg -rtsp_flags prefer_tcp -i "rtsp://$2:554/user=admin&password=&channel=1&stream=1.sdp" -acodec copy -vcodec copy -f hls -hls_time 30 -hls_list_size 32000 -hls_flags append_list+delete_segments -use_localtime 1 -hls_segment_filename "/home/zurikato/video-backup/$1/%Y-%m-%d_%H-%M-%S_hls.ts" /home/zurikato/video-backup/$1/playlist.m3u8

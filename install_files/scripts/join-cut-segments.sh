#!/usr/bin/env bash
folderPath=$1
cd $folderPath
#printf 'file %s\n' *.ts > videos.txt
ffmpeg -safe 0 -f concat -y -i videos.txt -c copy download.mp4
#ffmpeg -ss $startTime -t $totalSeconds -y -i videos.mp4 download.mp4

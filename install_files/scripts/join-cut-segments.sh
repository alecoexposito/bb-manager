#!/usr/bin/env bash
folderPath=$1
cd $folderPath
#ffmpeg -safe 0 -f concat -y -i videos.txt -c copy download.mp4

find 2*.ts | sed 's:\ :\\\ :g'| sed 's/^/file /' > fl.txt; ffmpeg -f concat -i fl.txt -c copy download.mp4; rm fl.txt
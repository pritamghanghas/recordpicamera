#!/bin/bash

# the script achieves following:
# does space management at startup
# records video from picam as well as a webcam for about 10mins. you can change those comandlines for chaging various ISP parameters
# after that it waits FINAL_REST number of seconds and issues shutdown of the whole system. Basically it shutsdown within 15min of coming up.
# once it has shutdown, power cycle is only way to start the system again and record anything new.
# The script is executed at startup with a systemd service.

# variables for naming files etc
duration=600000 # milliseconds, about 10mins to allow for process to complete. Becausae we reboot pi every hour.
TIMESTAMP=`date | tr " " "_" | tr ":" "-"`
FINAL_REST=180 # seconds
video_directory=/media/pi/data

################start of media management code########################
#make sure that we have the dirctories for media storage
# wait for mount to finish, blind sleep for the time being
sleep 100 # during this time the desktop should have started and usb drive mounted.

mkdir -p $video_directory

cd $video_directory

#convert all existing recordings to mp4
allH264Files=`ls -1 *.h264 | tr "\n" " "`
for h264file in $allH264Files
do
    MP4Box -add $h264file "$h264file.mp4"
    rm $h264file
done

# while free space is less than 8GB and there are still files to delete
freeGB=`df | grep "/dev/root" | tr -s " " |  cut -d " " -f 4`
echo "free space before cleanup is $freeGB\n"
mediaFiles=`ls -clt | tr -s " " | cut -d " " -f 9 | tr "\n" " "`
echo "current files are $mediaFiles\n"
while [ $freeGB -lt 8097152 ]  &&  [ ! -z $mediaFiles ]
do
    for file in $mediaFiles
    do
        echo "removing file $file\n"
        rm $file
        break;
    done
    freeGB=`df | grep "/dev/root" | tr -s " " |  cut -d " " -f 4`
    mediaFiles=`ls -clt | tr -s " " | cut -d " " -f 9 | tr "\n" " "`
done

#########################end of media management code#######################


########################### start with pi cam#######################################,
# one can get all possible values from raspistill cli program, It show all options when executed without any arguments.
# if the video is not good, capture it using options, right now we are just taking auto indoor mode with awb.
# this one runs in background, next one controls the script movement.
raspivid -t $duration -w 640 -h 480 -fps 90 -awb auto -ex sports -o picam-$TIMESTAMP.h264 &

############start with logiteh c170 cam #############################
# the various camera and other control when using webcam can only be controlled using v4l2-ctl
# execure "v4l2-ctl -L" on terminal to see all the options. Such option setting should be done before
# using ffmpeg

# v4l2-ctl -c saturation=50 # similarly other can be use for webcams.
# c170 will come as video0 only when connected before boot. otherwise pi camera will take up video0
# this can be autodected by parsing output of v4l2-ctl --list-devices, no need to do all that at this stage.
duration_ffmpeg=`expr $duration / 1000`
ffmpeg -f video4linux2 -t $duration_ffmpeg -s 640x480 -framerate 90 -i /dev/video0 -vcodec copy -t $duration_ffmpeg logi-c170-raw-$TIMESTAMP.mkv

# just to give sometime if you want to do something after this.
sleep $FINAL_REST
sudo halt 

cd -



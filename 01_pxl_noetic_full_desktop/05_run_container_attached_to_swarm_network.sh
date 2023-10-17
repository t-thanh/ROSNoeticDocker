#!/bin/bash

# Checking if host is aleady part of a swarm
swarm_status=$(docker info  2> /dev/null | grep -E "^[[:space:]]*Swarm:[[:space:]]*.?.?active" \
    | awk -F":" '{ print $2 }' | tr -d [:blank:]) 

if [ "$swarm_status" = "inactive" ]; then
    echo "[STOPPING] THIS HOST ISN'T PART OF A SWARM?!?!"
    exit -1
fi

# Is it the master or not?
if  docker swarm ca > /dev/null 2>&1; then
    container_hostname="swarm_master"
else
    # If it's a worker, generate a random hostname
    container_hostname=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
fi

# --device=/dev/video0:/dev/video0
# For non root usage:
# RUN sudo usermod -a -G video developer


if ! command -v glxinfo &> /dev/null
then
    echo "glxinfo command  not found! Execute \'sudo apt install mesa-utils\' to install it."
    exit
fi

vendor=`glxinfo | grep vendor | grep OpenGL | awk '{ print $4 }'`


if [ $vendor == "NVIDIA" ]; then
    docker run -it --rm \
        --name  $container_hostname \
        --hostname  $container_hostname \
        --device /dev/snd \
        --env="DISPLAY" \
        --env="QT_X11_NO_MITSHM=1" \
        --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
        -v `pwd`/../Commands/bin:/home/user/bin \
        -v `pwd`/../ExampleCode:/home/user/ExampleCode \
        -v `pwd`/../Projects/catkin_ws_src:/home/user/Projects/catkin_ws/src \
        -v `pwd`/../Data:/home/user/Data  \
        -env="XAUTHORITY=$XAUTH" \
        --gpus all \
        --publish-all=true \
        --network=pxl_ros_noetic_overlay_network \
        pxl_noetic_full_desktop:latest \
        bash
else
    docker run --privileged -it --rm \
        --name  $container_hostname \
        --hostname  $container_hostname \
        --volume=/tmp/.X11-unix:/tmp/.X11-unix \
        -v `pwd`/../Commands/bin:/home/user/bin \
        -v `pwd`/../ExampleCode:/home/user/ExampleCode \
        -v `pwd`/../Projects/catkin_ws_src:/home/user/Projects/catkin_ws/src \
	-v `pwd`/../Data:/home/user/Data \
        --device=/dev/dri:/dev/dri \
        --env="DISPLAY=$DISPLAY" \
        -e "TERM=xterm-256color" \
        --cap-add SYS_ADMIN --device /dev/fuse \
        --publish-all=true \
        --network=pxl_ros_noetic_overlay_network \
        pxl_noetic_full_desktop:latest \
        bash
fi

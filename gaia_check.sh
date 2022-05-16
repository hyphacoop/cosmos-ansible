#!/bin/bash 

gaia_host=$1
gaia_port=$2

# Waiting until gaiad responds
attempt_counter=0
max_attempts=60
until $(curl --output /dev/null --silent --head --fail http://$gaia_host:$gaia_port); do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "Tried connecting to gaiad for $attempt_counter times"
      exit 1
    fi

    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 1
done

# Checking to see if gaia is producing blocks
height=0
while [ $height -gt 10 ]
do
    height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r .result.block.header.height)
    echo "Current height is: $HEIGHT"
    sleep 1
done

echo "Hieght is more than 10 assuming gaiad is running fine"

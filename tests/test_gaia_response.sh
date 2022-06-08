#!/bin/bash 
# Test gaia is online.

gaia_host=$1
gaia_port=$2

# Waiting until gaiad responds
attempt_counter=0
max_attempts=60
echo "Waiting for gaia to come back online..."
until $(curl --output /dev/null --silent --head --fail http://$gaia_host:$gaia_port)
do
    if [ ${attempt_counter} -gt ${max_attempts} ]
    then
        echo ""
        echo "Tried connecting to gaiad for $attempt_counter times. Exiting."
        exit 3
    fi
    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 1
done
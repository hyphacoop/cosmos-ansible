#!/bin/bash 
# Check that blocks are being produced.

gaia_host=$1
gaia_port=$2
stop_height=$3

# Test gaia response
tests/test_gaia_response.sh $gaia_host $gaia_port
# Exit if test_gaia_response.sh fails
if [ $? != 0 ]
then
    exit 1
fi

# Get the current gaia version and block height from the API
gaiad_version=$(curl -s http://$gaia_host:$gaia_port/abci_info | jq -r .result.response.version)
cur_height=0
until [ ${cur_height} -gt 1 ]
do
    cur_height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r .result.block.header.height)
done

# Add stop_height to current height
let stop_height=$cur_height+$stop_height

# Check if gaia is producing blocks
test_counter=0
max_tests=2100
echo "Current gaiad version: $gaiad_version"
echo "Block height: $cur_height"
echo "Waiting to reach block height $stop_height..."
height=0
until [ $height -ge $stop_height ]
do
    sleep 5
    if [ ${test_counter} -gt ${max_tests} ]
    then
        echo "Queried gaia $test_counter times with a 5s wait between queries. A block height of $stop_height was not reached. Exiting."
        exit 2
    fi
    height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r .result.block.header.height)
    if [ -z "$height" ]
    then
        height=0
    fi
    echo "Block height: $height"
    test_counter=$(($test_counter+1))
done
echo "Gaia is producing blocks."

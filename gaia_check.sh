#!/bin/bash 
# This script is used for automated testing of the gaiad Ansible playbook
# and gaiad upgrade process using GitHub Actions.

gaia_host=$1
gaia_port=$2

# Waiting until gaiad responds
attempt_counter=0
max_attempts=60
until $(curl --output /dev/null --silent --head --fail http://$gaia_host:$gaia_port)
do
    if [ ${attempt_counter} -gt ${max_attempts} ]
    then
        echo ""
        echo "Tried connecting to gaiad for $attempt_counter times"
        exit 1
    fi

    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 1
done

# Get running gaiad version from API
gaiad_version=$(curl -s http://$gaia_host:$gaia_port/abci_info | jq -r .result.response.version)

# Checking to see if gaiad is producing blocks
test_counter=0
max_tests=60
cur_height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r .result.block.header.height)
let stop_height=cur_height+10
echo "Running gaiad version is: $gaiad_version"
echo "Current height is: $cur_height"
echo "Testing to height: $stop_height"
height=0
until [ $height -gt $stop_height ]
do
    if [ ${test_counter} -gt ${max_tests} ]
    then
        echo "Testing gaia for $test_counter times but did not reached height $stop_height"
        exit 2
    fi
    height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r .result.block.header.height)
    if [ -z "$height" ]
    then
        height=0
    fi
    echo "Current height is: $height"
    test_counter=$(($test_counter+1))
    sleep 1
done
echo "Gaiad is building blocks."

# Submit upgrade proposal
upgrade_height=$(($height+5))
echo "Submit upgrade proposal at height: $upgrade_height"
# TODO

# Show upgrade process / status
echo "Upgrade status:"
# TODO

# Waiting until gaiad responds
attempt_counter=0
max_attempts=60
until $(curl --output /dev/null --silent --head --fail http://$gaia_host:$gaia_port)
do
    if [ ${attempt_counter} -gt ${max_attempts} ]
    then
        echo ""
        echo "Tried connecting to gaiad for $attempt_counter times"
        exit 3
    fi

    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 1
done

# Get running upgraded version
gaiad_upgraded_version=$(curl -s http://$gaia_host:$gaia_port/abci_info | jq -r .result.response.version)

# Checking to see if gaiad is producing blocks
test_counter=0
max_tests=60
cur_height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r .result.block.header.height)
let stop_height=cur_height+10
echo "Running gaiad version is: $gaiad_upgraded_version"
echo "Current height is: $cur_height"
echo "Testing to height: $stop_height"
height=0
until [ $height -gt $stop_height ]
do
    if [ ${test_counter} -gt ${max_tests} ]
    then
        echo "Testing gaia for $test_counter times but did not reached height $stop_height"
        exit 4
    fi
    height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r .result.block.header.height)
    if [ -z "$height" ]
    then
        height=0
    fi
    echo "Current height is: $height"
    test_counter=$(($test_counter+1))
    sleep 1
done
echo "Upgraded gaiad is building blocks."

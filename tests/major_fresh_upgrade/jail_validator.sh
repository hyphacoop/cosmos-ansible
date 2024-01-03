#!/bin/bash
# Jail a validator by stopping the relevant service

service=$1
operator=$2

echo "Stopping $service..."
sudo systemctl stop $service

counter=1
while true; do
    jailed_status=$($CHAIN_BINARY q staking validator $operator --home $HOME_1 -o json | jq -r '.jailed')
    if [[ "$jailed_status" == "false" ]]; then
        echo "Validator $operator has not been jailed..."
        sleep 6
        counter=$(($counter+1))
    elif [[ "$jailed_status" == "true" ]]; then
        echo "Validator $operator has been jailed."
        break
    fi
    if [[ $counter -gt 10 ]]; then
        echo "Validator was not jailed."
        exit 1
    fi
done
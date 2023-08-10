#!/bin/bash
# Jail a validator by stopping the relevant service

service=$1
port=$2
address=$3
operator=$4

source tests/process_tx.sh

echo "Restarting $service..."
sudo systemctl start $service

counter=1
while true; do
    status=$(curl -s http://localhost:$port/status | jq -r '.result.sync_info.catching_up')
    if [[ "$status" == "true" ]]; then
        echo "Node is still catching up..."
        sleep 5
        counter=$(($counter+1))
    elif [[ "$status" == "false" ]]; then
        echo "Node is no longer catching up!"
        break
    elif [[ $counter -gt 10 ]]; then
        echo "Node could not catch up!"
        exit 1
    fi
done

submit_tx "tx slashing unjail --from $address --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y -o json" $CHAIN_BINARY $HOME_1

counter=1
while true; do
    jailed_status=$($CHAIN_BINARY q staking validator $operator --home $HOME_1 -o json | jq -r '.jailed')
    if [[ "$jailed_status" == "true" ]]; then
        echo "Validator $operator has not been unjailed..."
        sleep 2
        counter=$(($counter+1))
    elif [[ "$jailed_status" == "false" ]]; then
        echo "Validator $operator has been unjailed."
        break
    elif [[ $counter -gt 10 ]]; then
        echo "Validator was not unjailed."
        exit 1
    fi
done
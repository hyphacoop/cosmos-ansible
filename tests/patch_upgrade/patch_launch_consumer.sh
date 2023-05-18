#!/bin/bash
# Launch a consumer chain

echo "Patching add template with spawn time..."
spawn_time=$(date -u --iso-8601=ns | sed s/+00:00/Z/ | sed s/,/./)
jq -r --arg SPAWNTIME "$spawn_time" '.spawn_time |= $SPAWNTIME' tests/patch_upgrade/proposal-add-template.json > proposal-add-spawn.json
sed "s%\"chain_id\": \"\"%\"chain_id\": \"$CONSUMER_CHAIN_ID\"%g" proposal-add-spawn.json > proposal-add-$CONSUMER_CHAIN_ID.json
rm proposal-add-spawn.json

echo "Submitting proposal..."
$CHAIN_BINARY tx gov submit-proposal consumer-addition proposal-add-$CONSUMER_CHAIN_ID.json --gas auto --fees 1000$DENOM --from $MONIKER_2 --keyring-backend test --home $HOME_2 --chain-id $CHAIN_ID -b block -y
sleep 10

$CHAIN_BINARY tx gov vote $1 yes --gas auto --fees 1000$DENOM --from $MONIKER_1 --keyring-backend test --home $HOME_1 --chain-id $CHAIN_ID -b block -y
$CHAIN_BINARY tx gov vote $1 yes --gas auto --fees 1000$DENOM --from $MONIKER_2 --keyring-backend test --home $HOME_2 --chain-id $CHAIN_ID -b block -y
$CHAIN_BINARY q gov tally $1 --home $HOME_1

echo "Waiting for proposal to pass..."
sleep $VOTING_PERIOD

$CHAIN_BINARY q gov proposals --home $HOME_1

echo "Collecting the CCV state..."
$CHAIN_BINARY q provider consumer-genesis $CONSUMER_CHAIN_ID -o json --home $HOME_1 > ccv-pre.json
jq '.params |= . + {"soft_opt_out_threshold": "0.05"}' ccv-pre.json > ccv.json
jq '.' ccv.json

echo "Patching the consumer genesis file..."
jq -s '.[0].app_state.ccvconsumer = .[1] | .[0]' $CONSUMER_HOME_1/config/genesis.json ccv.json > consumer-genesis.json
cp consumer-genesis.json $CONSUMER_HOME_1/config/genesis.json
cp consumer-genesis.json $CONSUMER_HOME_2/config/genesis.json

echo "Starting the consumer chain..."
sudo systemctl enable $CONSUMER_SERVICE_1 --now
sudo systemctl enable $CONSUMER_SERVICE_2 --now

sleep 20
sudo journalctl -u $CONSUMER_SERVICE_1 | tail -n 200
sudo journalctl -u $CONSUMER_SERVICE_2 | tail -n 200
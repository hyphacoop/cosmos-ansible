#!/bin/bash
# Stop a consumer chain

# Inputs:
PROPOSAL_ID=$1

echo "Patching add template with stop time..."
stop_time=$(date -u --iso-8601=ns --date 'now + 15 seconds' | sed s/+00:00/Z/ | sed s/,/./)
jq -r --arg STOPTIME "$stop_time" '.stop_time |= $STOPTIME' tests/patch_upgrade/proposal-remove-template.json > proposal-remove.json
sed "s%\"chain_id\": \"\"%\"chain_id\": \"$CONSUMER_CHAIN_ID\"%g" proposal-remove.json > proposal-remove-$CONSUMER_CHAIN_ID.json
rm proposal-remove.json

echo "Passing proposal..."
$CHAIN_BINARY tx gov submit-proposal consumer-removal proposal-remove-$CONSUMER_CHAIN_ID.json --home $HOME_1 --gas auto --fees 1000$DENOM --from $MONIKER_2 --keyring-backend test --chain-id $CHAIN_ID -b block -y
$CHAIN_BINARY tx gov vote $PROPOSAL_ID yes --home $HOME_1 --gas auto --fees 1000$DENOM --from $MONIKER_2  --keyring-backend test --chain-id $CHAIN_ID -b block -y

echo "Waiting for proposal to pass and chain to stop..."
sleep 30

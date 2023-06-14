#!/bin/bash
# Stop a consumer chain

echo "Patching add template with stop time..."
stop_time=$(date -u --iso-8601=ns --date 'now + 15 seconds' | sed s/+00:00/Z/ | sed s/,/./)
jq -r --arg STOPTIME "$stop_time" '.stop_time |= $STOPTIME' tests/patch_upgrade/proposal-remove-template.json > proposal-remove.json
sed "s%\"chain_id\": \"\"%\"chain_id\": \"$CONSUMER_CHAIN_ID\"%g" proposal-remove.json > proposal-remove-$CONSUMER_CHAIN_ID.json
rm proposal-remove.json

echo "Passing proposal..."
proposal="$CHAIN_BINARY tx gov submit-proposal consumer-removal proposal-remove-$CONSUMER_CHAIN_ID.json --home $HOME_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees 1000$DENOM --from $WALLET_1 --keyring-backend test --chain-id $CHAIN_ID -b block -y -o json"
echo $proposal
txhash=$($proposal | jq -r .txhash)
# Wait for the proposal to go on chain
sleep 6

# Get proposal ID from txhash
echo "Getting proposal ID from txhash..."
$CHAIN_BINARY q tx $txhash --home $HOME_1
proposal_id=$($CHAIN_BINARY --output json q tx $txhash --home $HOME_1 | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')

$CHAIN_BINARY tx gov vote $proposal_id yes --home $HOME_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --from $WALLET_1  --keyring-backend test --chain-id $CHAIN_ID -b block -y

echo "Waiting for proposal to pass and chain to stop..."
sleep 30

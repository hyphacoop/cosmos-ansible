#!/bin/bash

echo "Patching add template with spawn time..."
spawn_time=$(date -u --iso-8601=ns -d '30 secs' | sed s/+00:00/Z/ | sed s/,/./) # 30 seconds in the future
jq -r --arg SPAWNTIME "$spawn_time" '.spawn_time |= $SPAWNTIME' tests/patch_upgrade/proposal-add-template.json > proposal-add-spawn.json

if $CHANGEOVER_HEIGHT_OFFSET ; then
    jq -r --argjson HEIGHT "$CHANGEOVER_REV_HEIGHT" '.initial_height.revision_height |= $HEIGHT' tests/patch_upgrade/proposal-add-template.json > proposal-add-height.json
    spawn_time=$(date -u --iso-8601=ns | sed s/+00:00/Z/ | sed s/,/./)
    jq -r --arg SPAWNTIME "$spawn_time" '.spawn_time |= $SPAWNTIME' proposal-add-height.json > proposal-add-spawn.json
fi

sed "s%\"chain_id\": \"\"%\"chain_id\": \"$CONSUMER_CHAIN_ID\"%g" proposal-add-spawn.json > proposal-add-$CONSUMER_CHAIN_ID.json
rm proposal-add-spawn.json

echo "Submitting proposal..."

if [ $COSMOS_SDK == "v45" ]; then
    echo "Preparing proposal with v45 command..."
    proposal="$CHAIN_BINARY tx gov submit-proposal consumer-addition proposal-add-$CONSUMER_CHAIN_ID.json --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --from $WALLET_2 --keyring-backend test --home $HOME_1 --chain-id $CHAIN_ID -y -o json"
elif [ $COSMOS_SDK == "v47" ]; then
echo "Preparing proposal with v47 command..."
    proposal="$CHAIN_BINARY tx gov submit-legacy-proposal consumer-addition proposal-add-$CONSUMER_CHAIN_ID.json --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --from $WALLET_2 --keyring-backend test --home $HOME_1  --chain-id $CHAIN_ID -y -o json"
fi
txhash=$($proposal | jq -r .txhash)
# Wait for the proposal to go on chain
sleep $(($COMMIT_TIMEOUT+2))

# Get proposal ID from txhash
echo "Getting proposal ID from txhash..."
$CHAIN_BINARY q tx $txhash --home $HOME_1
proposal_id=$($CHAIN_BINARY q tx $txhash --home $HOME_1 --output json | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')

echo "Voting on proposal $proposal_id..."
$CHAIN_BINARY tx gov vote $proposal_id yes --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --from $WALLET_1 --keyring-backend test --home $HOME_1 --chain-id $CHAIN_ID -y
sleep $(($COMMIT_TIMEOUT+2))
$CHAIN_BINARY q gov tally $proposal_id --home $HOME_1

echo "Waiting for proposal to pass..."
sleep $VOTING_PERIOD
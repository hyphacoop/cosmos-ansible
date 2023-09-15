#!/bin/bash

channel=$1

echo "Getting denom hash"
hash=$($CHAIN_BINARY q ibc-transfer denom-hash transfer/$channel/$CONSUMER_DENOM --home $HOME_1 -o json | jq -r '.hash')
hash=ibc/$hash
echo "hash: $hash"

reward=$($CHAIN_BINARY q distribution rewards $WALLET_1 --home $HOME_1 -o json | jq -r --arg DENOM "$hash" '.total[] | select(.denom==$DENOM)')
echo "Before: $reward"

echo "Registering denom"
echo "Patching proposal"
jq --arg DENOM "$hash" '.denoms_to_add = [$DENOM]' tests/v13_upgrade/proposal-rewards.json > proposal-$CONSUMER_DENOM.json

echo "Passing proposal..."
proposal="$CHAIN_BINARY tx gov submit-proposal change-reward-denoms proposal-$CONSUMER_DENOM.json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --from $WALLET_1 --keyring-backend test --home $HOME_1  --chain-id $CHAIN_ID -b block -y -o json"
echo "Submitting the change-reward-denoms proposal."
echo $proposal
sleep 5
txhash=$($proposal | jq -r .txhash)
proposal_id=$($CHAIN_BINARY --output json q tx $txhash --home $HOME_1 | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')
echo "Get proposal ID from txhash: $proposal_id"
$CHAIN_BINARY tx gov vote $proposal_id yes --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --from $WALLET_1  --keyring-backend test --home $HOME_1 --chain-id $CHAIN_ID -b block -y

echo "Waiting for the proposal to pass..."
sleep 15

echo "Denom registered"
reward=$($CHAIN_BINARY q distribution rewards $WALLET_1 --home $HOME_1 -o json | jq -r --arg DENOM "$hash" '.total[] | select(.denom==$DENOM).amount')
echo "After: $reward"

if [ -z "$reward" ]; then
  echo "Failure: denom not registered."
  exit 1
else
  echo "Success! Denom was registered."
fi






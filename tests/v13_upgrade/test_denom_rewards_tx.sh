#!/bin/bash

channel=$1

echo "Getting denom hash"
hash=$($CHAIN_BINARY q ibc-transfer denom-hash transfer/$channel/$CONSUMER_DENOM --home $HOME_1 -o json | jq -r '.hash')
hash=ibc/$hash
echo "hash: $hash"

reward=$($CHAIN_BINARY q distribution rewards $WALLET_1 --home $HOME_1 -o json | jq -r --arg DENOM "$hash" '.total[] | select(.denom==$DENOM)')
echo "Before: $reward"

echo "Registering denom"
tx="$CHAIN_BINARY tx provider register-consumer-reward-denom $hash --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --home $HOME_1 -b block -y"
echo $tx
$tx
sleep 10
echo "Denom registered"
reward=$($CHAIN_BINARY q distribution rewards $WALLET_1 --home $HOME_1 -o json | jq -r --arg DENOM "$hash" '.total[] | select(.denom==$DENOM).amount')
echo "After: $reward"

if [ -z "$reward" ]; then
  echo "Failure: denom not registered."
  exit 1
else
  echo "Success! Denom was registered."
fi
#!/bin/bash

channel_provider=$($CHAIN_BINARY q ibc channel end transfer channel-0 --home ~/.pfm1 --output json | jq -r '.channel.counterparty.channel_id')

echo "Provider chain channel ID: $channel_provider"
# provider -> channel-0 chain a -> channel-0 chain b -> channel-0 chain c (A->D)
target_denom_a_d=ibc/$(echo -n transfer/channel-0/transfer/channel-0/transfer/channel-0/uatom | shasum -a 256 | cut -d ' ' -f1 | tr '[a-z]' '[A-Z]')
# chain c -> channel-1 chain b -> channel-1 chain a -> channel-X provider (D->A)
target_denom_d_a=ibc/$(echo -n transfer/$channel_provider/transfer/channel-1/transfer/channel-1/uatom | shasum -a 256 | cut -d ' ' -f1 | tr '[a-z]' '[A-Z]')
echo "Target denom A->D: $target_denom_a_d"
echo "Target denom D->A: $target_denom_d_a"

d_start_balance=$($CHAIN_BINARY --home $PFM_HOME q bank balances $WALLET_1 -o json | jq -r --arg DENOM "$target_denom_a_d" '.balances[] | select(.denom==$DENOM).amount')
if [ -z "$d_start_balance" ]; then
  d_start_balance=0
fi
echo "Chain D starting balance in expected denom: $d_start_balance"

$CHAIN_BINARY tx ibc-transfer transfer transfer $channel_provider "pfm" --memo "{\"forward\": {\"receiver\": \"pfm\",\"port\": \"transfer\",\"channel\": \"channel-1\",\"timeout\": \"10m\",\"next\": {\"forward\": {\"receiver\": \"$WALLET_1\",\"port\": \"transfer\",\"channel\":\"channel-1\",\"timeout\":\"10m\"}}}}" 1000000$DENOM --from $WALLET_1 --gas auto --gas-prices 0.005$DENOM --gas-adjustment $GAS_ADJUSTMENT -y --home $HOME_1
echo "Waiting for the transfer to reach chain d..."
sleep $(($COMMIT_TIMEOUT*10))

d_end_balance=$($CHAIN_BINARY --home $PFM_HOME q bank balances $WALLET_1 -o json | jq -r --arg DENOM "$target_denom_a_d" '.balances[] | select(.denom==$DENOM).amount')
if [ -z "$d_end_balance" ]; then
  d_end_balance=0
fi
echo "Chain D ending balance in expected denom: $d_end_balance"

if [ $d_end_balance -gt $d_start_balance ]; then
  echo "Chain D balance has increased!"
else
  echo "Chain D balance has not increased!"
  exit 1
fi

a_start_balance=$($CHAIN_BINARY --home $HOME_1 q bank balances $WALLET_1 -o json | jq -r --arg DENOM "$target_denom_d_a" '.balances[] | select(.denom==$DENOM).amount')
if [ -z "$a_start_balance" ]; then
  a_start_balance=0
fi
echo "Chain A starting balance in expected denom: $a_start_balance"

$CHAIN_BINARY tx ibc-transfer transfer transfer channel-0 "pfm" --memo "{\"forward\": {\"receiver\": \"pfm\",\"port\": \"transfer\",\"channel\": \"channel-0\",\"timeout\": \"10m\",\"next\": {\"forward\": {\"receiver\": \"$WALLET_1\",\"port\": \"transfer\",\"channel\":\"channel-0\",\"timeout\":\"10m\"}}}}" 1000000$DENOM --from $WALLET_1 --gas auto --gas-prices 0.005$DENOM --gas-adjustment $GAS_ADJUSTMENT -y --home $PFM_HOME
echo "Waiting for the transfer to reach chain a..."
sleep $(($COMMIT_TIMEOUT*10))

a_end_balance=$($CHAIN_BINARY --home $HOME_1 q bank balances $WALLET_1 -o json | jq -r --arg DENOM "$target_denom_d_a" '.balances[] | select(.denom==$DENOM).amount')
if [ -z "$a_end_balance" ]; then
  a_end_balance=0
fi
echo "Chain A ending balance in expected denom: $a_end_balance"

if [ $a_end_balance -gt $a_start_balance ]; then
  echo "Chain A balance has increased!"
else
  echo "Chain A balance has not increased!"
  exit 1
fi

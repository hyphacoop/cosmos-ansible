#!/bin/bash

echo "Delegating with $WALLET_3..."
$CHAIN_BINARY tx staking delegate $VALOPER_1 100000000$DENOM --from $WALLET_3 -o json --home $HOME_1 --gas auto --gas-adjustment 1.2 -y | jq '.'
sleep 2
$CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq '.'

echo "Tokenizing shares with $WALLET_3..."
$CHAIN_BINARY tx staking tokenize-share $VALOPER_1 --from $WALLET_3 -o json --home $HOME_1 --gas auto --gas-adjustment 1.2 -y | jq '.'
sleep 2
$CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq '.'
$CHAIN_BINARY q bank balances $WALLET_3 --home $HOME_1 -o json | jq '.'

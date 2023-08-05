#!/bin/bash

echo "Delegating with $WALLET_2..."
$CHAIN_BINARY tx staking delegate $VALOPER_1 100000000$DENOM --from $WALLET_2 -o json --home $HOME_1 --gas auto --gas-adjustment 1.2 --fees $BASE_FEES$DENOM -y | jq '.'
sleep 2
$CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq '.'
$CHAIN_BINARY tx staking validator-bond $VALOPER_1 --from $WALLET_2 -o json --home $HOME_1 --gas auto --gas-adjustment 1.2 -y --fees $BASE_FEES$DENOM | jq '.'
$CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq '.'

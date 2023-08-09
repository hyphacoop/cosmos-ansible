#!/bin/bash

source tests/process_tx.sh

echo "Validator unbond from $WALLET_2..."
submit_tx "tx staking unbond $VALOPER_1 100000000$DENOM --from $WALLET_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1
$CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json
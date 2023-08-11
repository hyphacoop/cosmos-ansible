#!/bin/bash
# Transfer token ownership

source tests/process_tx.sh

tokenized_denom="$VALOPER_1/1"

echo "Transferring token ownership record..."
$CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq '.'

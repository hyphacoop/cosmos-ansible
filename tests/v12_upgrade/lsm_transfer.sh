#!/bin/bash
# Transfer token ownership

source tests/process_tx.sh

tokenized_denom="$VALOPER_1/1"

echo "Transferring token ownership record..."
record_id=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.id')
owner=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.owner')
echo "$owner owns record $record_id."
submit_tx "tx staking transfer-tokenize-share-record $record_id $WALLET_4 --from $owner --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1
owner=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.owner')
echo "$owner owns record $record_id."
submit_tx "tx staking transfer-tokenize-share-record $record_id $WALLET_3 --from $owner --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1
owner=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.owner')
echo "$owner owns record $record_id."
#!/bin/bash
# Transfer token ownership

source tests/process_tx.sh

tokenized_denom="$VALOPER_1/1"

record_id=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.id')
owner=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.owner')
echo "$owner owns record $record_id."

echo "Transferring token ownership record to WALLET_4..."
submit_tx "tx staking transfer-tokenize-share-record $record_id $WALLET_4 --from $owner --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1
owner=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.owner')
echo "$owner owns record $record_id."
if [[ "$owner" == "$WALLET_4" ]]; then
    echo "Token ownership transfer succeeded."
else
    echo "Token ownership transfer failed."
fi

echo "Transferring token ownership record back to WALLET_3..."
submit_tx "tx staking transfer-tokenize-share-record $record_id $WALLET_3 --from $owner --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1
owner=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.owner')
echo "$owner owns record $record_id."
if [[ "$owner" == "$WALLET_3" ]]; then
    echo "Token ownership transfer succeeded."
else
    echo "Token ownership transfer failed."
fi
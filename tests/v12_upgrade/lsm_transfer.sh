#!/bin/bash
# Transfer token ownership

source tests/process_tx.sh

tokenized_denom="$VALOPER_1/1"
$CHAIN_BINARY keys add new_owner --home $HOME_1
owner_address=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="acct_liquid").address')
echo "New owner address: $owner_address"

record_id=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.id')
owner=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.owner')
echo "$owner owns record $record_id."

echo "Transferring token ownership record to new_owner..."
submit_tx "tx staking transfer-tokenize-share-record $record_id $owner_address --from $owner --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1
owner=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.owner')
echo "$owner owns record $record_id."
if [[ "$owner" == "$owner_address" ]]; then
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

#!/bin/bash

echo "Sending tx staking delegate to host chain..."
$CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq '.'
message=$(jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json)
echo "Generating packet JSON..."
$STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$message" > delegate_packet.json
echo "Sending tx..."
$STRIDE_CHAIN_BINARY tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $MONIKER_1 --home $STRIDE_HOME_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment 1.2 -y -o json | jq '.'
sleep 20
$CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ica_address --home $HOME_1 -o json | jq '.'
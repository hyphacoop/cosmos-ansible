#!/bin/bash
# ICA delegation failure cases

source tests/process_tx.sh

echo "** Failure case 1: ICA attempts to delegate without validator bond **"
$CHAIN_BINARY q staking validator $VALOPER_3 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'

jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > delegate-fail-1.json
message=$(jq -r --arg ADDRESS "$VALOPER_3" '.validator_address = $ADDRESS' delegate-fail-1.json)
echo "Generating packet JSON..."
$STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$message" > delegate_packet.json
echo "Sending tx staking delegate to host chain..."
submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
# $STRIDE_CHAIN_BINARY tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $MONIKER_1 --home $STRIDE_HOME_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment 1.2 -y -o json | jq '.'
echo "Waiting for delegation to go on-chain..."
sleep 10
$CHAIN_BINARY q staking validator $VALOPER_3 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $$ICA_ADDRESS -o json --home $HOME_1 | jq '.'

echo "** Failure case 2: ICA attempts to delegate, breaching the validator liquid staking cap **"
$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'

# submit_bad_tx "tx staking tokenize-share $VALOPER_2 100000000$DENOM $WALLET_5 --from $WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > delegate-val-breach-1.json
jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' delegate-val-breach-1.json > delegate-val-breach-2.json
jq -r '.amount.amount = "100000000"' delegate-val-breach-2.json > delegate-val-breach-3.json
cat delegate-val-breach-3.json
echo "Generating packet JSON..."
$STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat delegate-val-breach-3.json)" > delegate_packet.json
echo "Sending tx staking delegate to host chain..."
submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
echo "Waiting for delegation to go on-chain..."
sleep 10

$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'

echo "** Failure case 3: ICA attempts to delegate, breaching the global liquid staking cap **"
$CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'

# submit_bad_tx "tx staking tokenize-share $VALOPER_1 140000000$DENOM $WALLET_5 --from $WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > delegate-global-breach-1.json
jq -r --arg ADDRESS "$VALOPER_1" '.validator_address = $ADDRESS' delegate-global-breach-1.json > delegate-global-breach-2.json
jq -r '.amount.amount = "140000000"' delegate-global-breach-2.json > delegate-global-breach-3.json
cat delegate-global-breach-3.json
echo "Generating packet JSON..."
$STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat delegate-global-breach-3.json)" > delegate_packet.json
echo "Sending tx staking delegate to host chain..."
submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
echo "Waiting for delegation to go on-chain..."
sleep 10

$CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
#!/bin/bash
# ICA delegation failure cases

source tests/process_tx.sh

validator_breach=100000000
global_breach=140000000

starting_balance=$($CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq -r '.balances[] | select(.denom=="uatom").amount')
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'

echo "** Failure case 1: ICA attempts to delegate without validator bond **"
# $CHAIN_BINARY q staking validator $VALOPER_3 -o json --home $HOME_1 | jq '.'
# $CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'

jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > delegate-fail-1.json
message=$(jq -r --arg ADDRESS "$VALOPER_3" '.validator_address = $ADDRESS' delegate-fail-1.json)
echo "Generating packet JSON..."
$STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$message" > delegate_packet.json
echo "Sending tx staking delegate to host chain..."
submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
# $STRIDE_CHAIN_BINARY tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $MONIKER_1 --home $STRIDE_HOME_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment 1.2 -y -o json | jq '.'
echo "Waiting for delegation to go on-chain..."
sleep 10
# $CHAIN_BINARY q staking validator $VALOPER_3 -o json --home $HOME_1 | jq '.'
# $CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'

balance=$($CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq -r '.balances[] | select(.denom=="uatom").amount')
if [[ $balance -eq $starting_balance ]]; then
    echo "Failure case 1 success: balance remains unchanged"
else
    echo "Failure case 1 failure: balance has changed"
    exit 1
fi

echo "** Failure case 2: ICA attempts to delegate, breaching the validator liquid staking cap **"
# $CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
# $CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'

jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > delegate-val-breach-1.json
jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' delegate-val-breach-1.json > delegate-val-breach-2.json
jq -r --arg AMOUNT "$validator_breach" '.amount.amount = $AMOUNT' delegate-val-breach-2.json > delegate-val-breach-3.json
cp delegate-val-breach-3.json val-breach.json
cat val-breach.json

echo "Generating packet JSON..."
$STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat val-breach.json)" > delegate_packet.json
echo "Sending tx staking delegate to host chain..."
submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
echo "Waiting for delegation to go on-chain..."
sleep 10

# $CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
# $CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
balance=$($CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq -r '.balances[] | select(.denom=="uatom").amount')
if [[ $balance -eq $starting_balance ]]; then
    echo "Failure case 2 success: balance remains unchanged"
else
    echo "Failure case 2 failure: balance has changed"
    exit 1
fi

echo "** Failure case 3: ICA attempts to delegate, breaching the global liquid staking cap **"
# $CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq '.'
# $CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'

jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > delegate-global-breach-1.json
jq -r --arg ADDRESS "$VALOPER_1" '.validator_address = $ADDRESS' delegate-global-breach-1.json > delegate-global-breach-2.json
jq -r --arg AMOUNT "$global_breach" '.amount.amount = $AMOUNT' delegate-global-breach-2.json > delegate-global-breach-3.json
cat delegate-global-breach-3.json
cp delegate-global-breach-3.json global-breach.json
echo "Generating packet JSON..."
$STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat global-breach.json)" > delegate_packet.json
echo "Sending tx staking delegate to host chain..."
submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
echo "Waiting for delegation to go on-chain..."
sleep 10

# $CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq '.'
# $CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'

balance=$($CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq -r '.balances[] | select(.denom=="uatom").amount')
if [[ $balance -eq $starting_balance ]]; then
    echo "Failure case 3 success: balance remains unchanged"
else
    echo "Failure case 3 failure: balance has changed"
    exit 1
fi

val1=$($CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq '.jailed')
val2=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.jailed')
val3=$($CHAIN_BINARY q staking validator $VALOPER_3 -o json --home $HOME_1 | jq '.jailed')
echo "Validator jailed status: $val1 $val2 $val3"


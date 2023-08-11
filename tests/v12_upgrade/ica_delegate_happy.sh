#!/bin/bash
# Happy path for liquid staking provider

source tests/process_tx.sh

$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
pre_delegation_tokens=$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens'
pre_delegation_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
pre_delegation_liquid_shares=$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.total_liquid_shares'
exchange_rate=$(echo "$shares/$tokens" | bc -l)
expected_liquid_increase=$(echo "$exchange_rate*20000000" | bc -l)

jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > delegate-happy.json
message=$(jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' delegate-happy.json)
echo "Generating packet JSON..."
$STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$message" > delegate_packet.json
echo "Sending tx staking delegate to host chain..."
submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
# $STRIDE_CHAIN_BINARY tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $MONIKER_1 --home $STRIDE_HOME_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment 1.2 -y -o json | jq '.'
echo "Waiting for delegation to go on-chain..."
sleep 10

$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
post_delegation_tokens=$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens'
post_delegation_liquid_shares=$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.total_liquid_shares'


tokens_delta=$(($post_delegation_tokens-$pre_delegation_tokens))
liquid_shares_delta=$(echo "$post_delegation_liquid_shares-$pre_delegation_liquid_shares" | bc -l)
echo "Expected increase in liquid shares: $expected_liquid_increase"
echo "Val tokens delta: $tokens_delta, liquid shares delta: $liquid_shares_delta"

# $CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
# jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > delegate-2.json
# message=$(jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' delegate-2.json)
# echo "Generating packet JSON..."
# $STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$message" > delegate_packet.json
# echo "Sending tx..."
# $STRIDE_CHAIN_BINARY tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $MONIKER_1 --home $STRIDE_HOME_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment 1.2 -y -o json | jq '.'
# sleep 10
# $CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'

#!/bin/bash
# Happy path for liquid staking provider

source tests/process_tx.sh

delegate=20000000

pre_delegation_tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
echo "Pre-delegation val tokens: $pre_delegation_tokens"
pre_delegation_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
echo "Pre-delegation val shares: $pre_delegation_shares"
pre_delegation_liquid_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.liquid_shares')
echo "Pre-delegation val liquid shares: $pre_delegation_liquid_shares"
exchange_rate=$(echo "$pre_delegation_shares/$pre_delegation_tokens" | bc -l)
echo "Exchange rate: $exchange_rate"
expected_liquid_increase=$(echo "$exchange_rate*$delegate" | bc -l)
expected_liquid_increase=${expected_liquid_increase%.*}
echo "Expected increase in liquid shares: $expected_liquid_increase"

jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > delegate-happy.json
jq -r --arg AMOUNT "$delegate" '.amount.amount = $AMOUNT' delegate-happy.json > delegate-happy-2.json
message=$(jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' delegate-happy-2.json)
echo "Generating packet JSON..."
$STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$message" > delegate_packet.json
echo "Sending tx staking delegate to host chain..."
tests/v12_upgrade/log_lsm_data.sh lsp-happy pre-ica-delegate-1 $ICA_ADDRESS $delegate
submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
echo "Waiting for delegation to go on-chain..."
sleep $(($COMMIT_TIMEOUT*4))
tests/v12_upgrade/log_lsm_data.sh lsp-happy post-ica-delegate-1 $ICA_ADDRESS $delegate

$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
post_delegation_tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
post_delegation_liquid_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.liquid_shares')

tokens_delta=$(($post_delegation_tokens-$pre_delegation_tokens))
liquid_shares_delta=$(echo "$post_delegation_liquid_shares-$pre_delegation_liquid_shares" | bc -l)
liquid_shares_delta=${liquid_shares_delta%.*}
echo "Expected increase in liquid shares: $expected_liquid_increase"
echo "Val tokens delta: $tokens_delta, liquid shares delta: $liquid_shares_delta"

if [[ $tokens_delta -eq $delegate ]]; then
    echo "Delegation success: expected tokens increase ($tokens_delta = $delegate)"
elif [[ $(($tokens_delta-$delegate)) -eq 1 ]]; then
    echo "Delegation success: tokens increase off by 1"
elif [[ $(($delegate-$tokens_delta)) -eq 1 ]]; then
    echo "Delegation success: tokens increase off by 1"
else
    echo "Accounting failure: unexpected tokens decrease ($total_delta != $tokenize)"
    exit 1
fi

if [[ $liquid_shares_delta -eq $expected_liquid_increase ]]; then
    echo "Delegation success: expected liquid shares increase ($liquid_shares_delta = $expected_liquid_increase)"
elif [[ $(($liquid_shares_delta-$expected_liquid_increase)) -eq 1 ]]; then
    echo "Delegation success: liquid shares increase off by 1"
elif [[ $(($expected_liquid_increase-$liquid_shares_delta)) -eq 1 ]]; then
    echo "Delegation success: liquid shares increase off by 1"
else
    echo "Accounting failure: unexpected liquid shares increase ($liquid_shares_delta != $expected_liquid_increase)"
    exit 1
fi

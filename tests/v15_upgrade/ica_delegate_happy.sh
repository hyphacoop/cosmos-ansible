#!/bin/bash
# Happy path for liquid staking provider

source tests/process_tx.sh

delegate=20000000
bond_delegation=20000000

$CHAIN_BINARY keys add lsp_happy_bonding_$LSP_COUNT --home $HOME_1
lsp_happy_bonding=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r --arg LSP "lsp_happy_bonding_$LSP_COUNT" '.[] | select(.name==$LSP).address')

echo "Funding bonding account..."
submit_tx "tx bank send $WALLET_1 $lsp_happy_bonding 50000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1

echo "** LIQUID STAKING PROVIDER HAPPY PATH> 1: DELEGATE AND BOND **"
    echo "Delegating and bonding with bonding_account..."
    shares_1=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
    tokens_1=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.tokens')
    bond_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    echo "Bond shares: $bond_shares_1"
    exchange_rate_1=$(echo "$shares_1/$tokens_1" | bc -l)
    echo "Exchange rate: $exchange_rate_1"
    expected_shares_increase=$(echo "$bond_delegation*$exchange_rate_1" | bc -l)
    expected_shares=$(echo "$expected_shares_increase+$bond_shares_1" | bc -l)
    echo "Expected shares: $expected_shares"
    expected_shares=${expected_shares%.*}

    tests/v12_upgrade/log_lsm_data.sh accounting pre-delegate-1 $lsp_happy_bonding $bond_delegation
    submit_tx "tx staking delegate $VALOPER_2 $bond_delegation$DENOM --from $lsp_happy_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-delegate-1 $lsp_happy_bonding $bond_delegation
    $CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'
    tests/v12_upgrade/log_lsm_data.sh accounting pre-bond-1 $lsp_happy_bonding -
    submit_tx "tx staking validator-bond $VALOPER_2 --from $lsp_happy_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --gas-prices $GAS_PRICE$DENOM" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-bond-1 $lsp_happy_bonding -
    $CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'

    bond_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    bond_shares_2=${bond_shares_2%.*}
    echo "Validator 2 bond shares: $bond_shares_2, expected: $expected_shares"
    if [[ $bond_shares_2 -eq $expected_shares  ]]; then
        echo "Validator bond successful."
    elif [[ $(($bond_shares_2-$expected_shares)) -eq 1 ]]; then
        echo "Validator bond successful: bond shares increase off by 1"
    elif [[ $(($expected_shares-$bond_shares_2)) -eq 1 ]]; then
        echo "Validator bond successful: bond shares increase off by 1"
    else
        echo "Accounting failure: unexpected validator bond shares increase ($bond_shares_2 != $expected_shares)"
        exit 1 
    fi

echo "** LIQUID STAKING PROVIDER HAPPY PATH> 2: DELEGATE VIA ICA **"
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
    # message=$(jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' delegate-happy-2.json)
    # echo $message
    # echo "Generating packet JSON..."
    # $STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$message" > delegate_packet.json
    jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' delegate-happy-2.json > delegate-happy-3.json
    cat delegate-happy-3.json
    echo "Generating packet JSON..."
    $STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat delegate-happy-3.json)" --encoding proto3 > delegate_packet.json # Stride v18
    # $STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat delegate-happy-3.json)" > delegate_packet.json # Stride v12
    echo "Sending tx staking delegate to host chain..."
    tests/v12_upgrade/log_lsm_data.sh lsp-happy pre-ica-delegate-1 $ICA_ADDRESS $delegate
    
    $CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
    $CHAIN_BINARY q staking delegations $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
    $CHAIN_BINARY q staking params --home $HOME_1
    submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
    echo "Waiting for delegation to go on-chain..."
    sleep $(($COMMIT_TIMEOUT*20))
    journalctl -u $RELAYER | tail -n 50
    tests/v12_upgrade/log_lsm_data.sh lsp-happy post-ica-delegate-1 $ICA_ADDRESS $delegate
    
    $CHAIN_BINARY q staking delegations $ICA_ADDRESS -o json --home $HOME_1 | jq '.'
    $CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
    post_delegation_tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
    echo "Post-delegation val tokens: $post_delegation_tokens"
    post_delegation_liquid_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.liquid_shares')
    echo "Post-delegation val liquid shares: $post_delegation_liquid_shares"

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
        echo "Accounting failure: unexpected tokens increase ($tokens_delta != $delegate)"
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

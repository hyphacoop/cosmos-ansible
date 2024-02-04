#!/bin/bash
# ICA delegation accounting tests

source tests/process_tx.sh

bond_delegation=100000000
delegation=10000000
undelegation=5000000
redelegation=2000000

$CHAIN_BINARY keys add lsp_accounting_bonding --home $HOME_1
lsp_accounting_bonding=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="lsp_accounting_bonding").address')

echo "Funding bonding account..."
submit_tx "tx bank send $WALLET_1 $lsp_accounting_bonding 150000000$DENOM --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1

delegator_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
validator_bond_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')

echo "Delegating with lsp_accounting_bonding..."
tests/v12_upgrade/log_lsm_data.sh lsp-accounting pre-delegate-1 $lsp_accounting_bonding $bond_delegation
submit_tx "tx staking delegate $VALOPER_1 $bond_delegation$DENOM --from $lsp_accounting_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh lsp-accounting post-delegate-1 $lsp_accounting_bonding $bond_delegation

delegator_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
shares_diff=$((${delegator_shares_2%.*}-${delegator_shares_1%.*})) # remove decimal portion
echo "Delegator shares difference: $shares_diff"
if [[ $shares_diff -ne $bond_delegation ]]; then
    echo "Delegation unsuccessful."
    exit 1
fi

echo "Validator bond with lsp_accounting_bonding..."
tests/v12_upgrade/log_lsm_data.sh lsp-accounting pre-bond-1 $lsp_accounting_bonding -
submit_tx "tx staking validator-bond $VALOPER_1 --from $lsp_accounting_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --gas-prices $GAS_PRICE$DENOM" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh lsp-accounting post-bond-1 $lsp_accounting_bonding -

validator_bond_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
bond_shares_diff=$((${validator_bond_shares_2%.*}-${validator_bond_shares_1%.*})) # remove decimal portion
echo "Bond shares difference: $bond_shares_diff"
if [[ $shares_diff -ne $bond_delegation  ]]; then
    echo "Validator bond unsuccessful."
    exit 1
fi

echo "** LIQUID STAKING PROVIDER ACCOUNTING TESTS> 1: DELEGATION INCREASES VALIDATOR LIQUID SHARES AND LIQUID STAKED TOKENS **"
    
    pre_delegation_tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
    pre_delegation_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.delegator_shares')
    pre_delegation_liquid_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.liquid_shares')
    pre_delegation_total_liquid=$($CHAIN_BINARY q staking total-liquid-staked -o json --home $HOME_1 | jq -r '.tokens')

    exchange_rate=$(echo "$pre_delegation_shares/$pre_delegation_tokens" | bc -l)
    expected_liquid_increase=$(echo "$exchange_rate*$delegation" | bc -l)
    expected_liquid_increase=${expected_liquid_increase%.*}
    echo "Expected liquid shares increase: $expected_liquid_increase"

    jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > acct-del-1.json
    jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' acct-del-1.json > acct-del-2.json
    jq -r --arg AMOUNT "$delegation" '.amount.amount = $AMOUNT' acct-del-2.json > acct-del-3.json
    cp acct-del-3.json acct-del.json

    echo "Generating packet JSON..."
    $STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat acct-del.json)" > delegate_packet.json
    echo "Sending tx staking delegate to host chain..."
    tests/v12_upgrade/log_lsm_data.sh lsp-accounting pre-delegate-2 $ICA_ADDRESS $delegation
    submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
    echo "Waiting for delegation to go on-chain..."
    sleep $(($COMMIT_TIMEOUT*4))
    tests/v12_upgrade/log_lsm_data.sh lsp-accounting post-delegate-2 $ICA_ADDRESS $delegation

    post_delegation_tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
    post_delegation_liquid_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.liquid_shares')
    post_delegation_total_liquid=$($CHAIN_BINARY q staking total-liquid-staked -o json --home $HOME_1 | jq -r '.tokens')

    tokens_delta=$(($post_delegation_tokens-$pre_delegation_tokens))
    liquid_shares_delta=$(echo "$post_delegation_liquid_shares-$pre_delegation_liquid_shares" | bc -l)
    liquid_shares_delta=${liquid_shares_delta%.*}
    total_liquid_delta=$(echo "$post_delegation_total_liquid-$pre_delegation_total_liquid" | bc -l)
    echo "Expected increase in liquid shares: $expected_liquid_increase"
    echo "Val tokens delta: $tokens_delta, liquid shares delta: $liquid_shares_delta, total liquid tokens delta: $total_liquid_delta"

    if [[ $liquid_shares_delta -eq $expected_liquid_increase ]]; then
        echo "Accounting test 1 success: expected liquid shares increase ($liquid_shares_delta = $expected_liquid_increase)"
    elif [[ $(($liquid_shares_delta-$expected_liquid_increase)) -eq 1 ]]; then
        echo "Accounting test 1 success: liquid shares increase off by 1"
    elif [[ $(($expected_liquid_increase-$liquid_shares_delta)) -eq 1 ]]; then
        echo "Accounting test 1 success: liquid shares increase off by 1"
    else
        echo "Accounting test 1 failure: unexpected liquid shares decrease ($liquid_shares_delta != $expected_liquid_increase)"
        exit 1
    fi

    if [[ $tokens_delta -eq $delegation ]]; then
        echo "Accounting test 1 success: expected tokens increase ($tokens_delta = $delegation)"
    elif [[ $(($tokens_delta-$delegation)) -eq 1 ]]; then
        echo "Accounting test 1 success: tokens increase off by 1"
    elif [[ $(($delegation-$tokens_delta)) -eq 1 ]]; then
        echo "Accounting test 1 success: tokens increase off by 1"
    else
        echo "Accounting test 1 failure: unexpected liquid tokens decrease ($total_delta != $delegation)"
        exit 1
    fi

echo "** LIQUID STAKING PROVIDER ACCOUNTING TESTS> 2: UNDELEGATION DECREASES VALIDATOR LIQUID SHARES AND LIQUID STAKED TOKENS **"
    
    pre_undelegation_tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
    pre_undelegation_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
    pre_undelegation_liquid_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.liquid_shares')
    pre_delegation_total_liquid=$($CHAIN_BINARY q staking total-liquid-staked -o json --home $HOME_1 | jq -r '.tokens')
    exchange_rate=$(echo "$pre_undelegation_shares/$pre_undelegation_tokens" | bc -l)
    expected_liquid_decrease=$(echo "$exchange_rate*$undelegation" | bc -l)
    expected_liquid_decrease=${expected_liquid_decrease%.*}

    jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-undelegate.json > acct-undel-1.json
    jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' acct-undel-1.json > acct-undel-2.json
    jq -r --arg AMOUNT "$undelegation" '.amount.amount = $AMOUNT' acct-undel-2.json > acct-undel-3.json
    cp acct-undel-3.json acct-undel.json

    echo "Generating packet JSON..."
    $STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat acct-undel.json)" > undelegate_packet.json
    echo "Sending tx staking undelegate to host chain..."
    tests/v12_upgrade/log_lsm_data.sh lsp-accounting pre-undelegate-1 $ICA_ADDRESS $undelegation
    submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 undelegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
    echo "Waiting for undelegation to go on-chain..."
    sleep $(($COMMIT_TIMEOUT*4))
    tests/v12_upgrade/log_lsm_data.sh lsp-accounting post-undelegate-1 $ICA_ADDRESS $undelegation

    post_undelegation_tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
    post_undelegation_liquid_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.liquid_shares')

    tokens_delta=$(($pre_undelegation_tokens-$post_undelegation_tokens))
    liquid_shares_delta=$(echo "$pre_undelegation_liquid_shares-$post_undelegation_liquid_shares" | bc -l)
    liquid_shares_delta=${liquid_shares_delta%.*}
    echo "Expected decrease in liquid shares: $expected_liquid_decrease"
    echo "Val tokens delta: $tokens_delta, liquid shares delta: $liquid_shares_delta"

    if [[ $liquid_shares_delta -eq $expected_liquid_decrease ]]; then
        echo "Accounting test 2 success: expected liquid shares decrease ($liquid_shares_delta = $expected_liquid_decrease)"
    elif [[ $(($liquid_shares_delta-$expected_liquid_decrease)) -eq 1 ]]; then
        echo "Accounting test 2 success: liquid shares increase off by 1"
    elif [[ $(($expected_liquid_decrease-$liquid_shares_delta)) -eq 1 ]]; then
        echo "Accounting test 2 success: liquid shares increase off by 1"
    else
        echo "Accounting test 2 failure: unexpected liquid shares decrease ($liquid_shares_delta != $expected_liquid_decrease)"
        exit 1
    fi

    if [[ $tokens_delta -eq $undelegation ]]; then
        echo "Accounting test 2 success: expected tokens increase ($tokens_delta = $undelegation)"
    elif [[ $(($tokens_delta-$undelegation)) -eq 1 ]]; then
        echo "Accounting test 2 success: tokens increase off by 1"
    elif [[ $(($undelegation-$tokens_delta)) -eq 1 ]]; then
        echo "Accounting test 2 success: tokens increase off by 1"
    else
        echo "Accounting test 2 failure: unexpected liquid tokens decrease ($tokens_delta != $undelegation)"
        exit 1
    fi

echo "** LIQUID STAKING PROVIDER ACCOUNTING TESTS> 3: REDELEGATION DECREASES SRC VALIDATOR LIQUID SHARES AND INCREASES DEST VALIDATOR LIQUID SHARES **"
    pre_redelegation_tokens_1=$($CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq -r '.tokens')
    pre_redelegation_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
    pre_redelegation_liquid_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq -r '.liquid_shares')
    exchange_rate_1=$(echo "$pre_redelegation_shares_1/$pre_redelegation_tokens_1" | bc -l)
    echo "Exchange rate for val1: $exchange_rate_1"

    pre_redelegation_tokens_2=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
    pre_redelegation_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
    pre_redelegation_liquid_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.liquid_shares')
    exchange_rate_2=$(echo "$pre_redelegation_shares_2/$pre_redelegation_tokens_2" | bc -l)
    echo "Exchange rate for val2: $exchange_rate_2"

    expected_liquid_decrease=$(echo "$exchange_rate_2*$redelegation" | bc -l)
    expected_liquid_decrease=${expected_liquid_decrease%.*}
    expected_liquid_increase=$(echo "$exchange_rate_1*$redelegation" | bc -l)
    expected_liquid_increase=${expected_liquid_increase%.*}

    jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-redelegate.json > acct-redel-1.json
    jq -r --arg ADDRESS "$VALOPER_2" '.validator_src_address = $ADDRESS' acct-redel-1.json > acct-redel-2.json
    jq -r --arg ADDRESS "$VALOPER_1" '.validator_dst_address = $ADDRESS' acct-redel-2.json > acct-redel-3.json
    jq -r --arg AMOUNT "$redelegation" '.amount.amount = $AMOUNT' acct-redel-3.json > acct-redel-4.json
    cp acct-redel-4.json redel.json

    echo "Generating packet JSON..."
    $STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat redel.json)" > redelegate_packet.json
    echo "Sending tx staking redelegate to host chain..."
    tests/v12_upgrade/log_lsm_data.sh lsp-accounting pre-redelegate-1 $ICA_ADDRESS $redelegation
    submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 redelegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
    echo "Waiting for redelegation to go on-chain..."
    sleep $(($COMMIT_TIMEOUT*4))
    tests/v12_upgrade/log_lsm_data.sh lsp-accounting post-redelegate-1 $ICA_ADDRESS $redelegation

    post_redelegation_tokens_1=$($CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq -r '.tokens')
    post_redelegation_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
    post_redelegation_liquid_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq -r '.liquid_shares')
    post_redelegation_tokens_2=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.tokens')
    post_redelegation_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
    post_redelegation_liquid_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.liquid_shares')

    liquid_shares_delta_1=$(echo "$post_redelegation_liquid_shares_1-$pre_redelegation_liquid_shares_1" | bc -l)
    liquid_shares_delta_1=${liquid_shares_delta_1%.*}
    liquid_shares_delta_2=$(echo "$pre_redelegation_liquid_shares_2-$post_redelegation_liquid_shares_2" | bc -l)
    liquid_shares_delta_2=${liquid_shares_delta_2%.*}
    echo "Expected increase in val 1 liquid shares: $expected_liquid_increase"
    echo "Val 1 liquid shares delta: $liquid_shares_delta_1"
    echo "Expected decrease in val 2 liquid shares: $expected_liquid_decrease"
    echo "Val 2 liquid shares delta: $liquid_shares_delta_2"

    if [[ $liquid_shares_delta_2 -eq $expected_liquid_decrease ]]; then
        echo "Accounting test 3 success: expected liquid shares decrease ($liquid_shares_delta_2 = $expected_liquid_decrease)"
    elif [[ $(($liquid_shares_delta_2-$expected_liquid_decrease)) -eq 1 ]]; then
        echo "Accounting test 3 success: liquid shares increase off by 1"
    elif [[ $(($expected_liquid_decrease-$liquid_shares_delta_2)) -eq 1 ]]; then
        echo "Accounting test 3 success: liquid shares increase off by 1"
    else
        echo "Accounting test 3 failure: unexpected liquid shares decrease ($liquid_shares_delta_2 != $expected_liquid_decrease)"
        exit 1
    fi

    if [[ $liquid_shares_delta_1 -eq $expected_liquid_increase ]]; then
        echo "Accounting test 3 success: expected liquid shares increase ($liquid_shares_delta_1 = $expected_liquid_increase)"
    elif [[ $(($liquid_shares_delta_1-$expected_liquid_increase)) -eq 1 ]]; then
        echo "Accounting test 3 success: liquid shares increase off by 1"
    elif [[ $(($expected_liquid_increase-$liquid_shares_delta_1)) -eq 1 ]]; then
        echo "Accounting test 3 success: liquid shares increase off by 1"
    else
        echo "Accounting test 3 failure: unexpected liquid shares decrease ($liquid_shares_delta_1 != $expected_liquid_increase)"
        exit 1
    fi



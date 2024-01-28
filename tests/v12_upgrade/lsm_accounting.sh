#!/bin/bash
# Implement accounting tests

source tests/process_tx.sh

delegation=20000000
tokenize=10000000
unbond=10000000
tokenized_denom=$VALOPER_2/5

$CHAIN_BINARY keys add accounting_bonding --home $HOME_1
$CHAIN_BINARY keys add accounting_liquid --home $HOME_1

accounting_bonding=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="accounting_bonding").address')
accounting_liquid=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="accounting_liquid").address')

echo "Funding bonding and tokenizing accounts..."
submit_tx "tx bank send $WALLET_1 $accounting_bonding 100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $accounting_liquid  100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1

echo "Delegating and bonding with bonding_account..."
shares_1=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
tokens_1=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.tokens')
bond_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
echo "Bond shares: $bond_shares_1"
exchange_rate_1=$(echo "$shares_1/$tokens_1" | bc -l)
echo "Exchange rate: $exchange_rate_1"
expected_shares_increase=$(echo "$delegation*$exchange_rate_1" | bc -l)
expected_shares=$(echo "$expected_shares_increase+$bond_shares_1" | bc -l)
echo "Expected shares: $expected_shares"
expected_shares=${expected_shares%.*}

tests/v12_upgrade/log_lsm_data.sh accounting pre-delegate-1 $accounting_bonding $delegation
submit_tx "tx staking delegate $VALOPER_2 $delegation$DENOM --from $accounting_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh accounting post-delegate-1 $accounting_bonding $delegation
$CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'
tests/v12_upgrade/log_lsm_data.sh accounting pre-bond-1 $accounting_bonding -
submit_tx "tx staking validator-bond $VALOPER_2 --from $accounting_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --gas-prices $GAS_PRICE$DENOM" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh accounting post-bond-1 $accounting_bonding -
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

echo "** ACCOUNTING TESTS> 1: TOKENIZATION INCREASES VALIDATOR LIQUID SHARES AND GLOBAL LIQUID STAKED TOKENS **"

    echo "Delegating with tokenizing_account..."
    tests/v12_upgrade/log_lsm_data.sh accounting pre-delegate-2 $accounting_liquid $delegation
    submit_tx "tx staking delegate $VALOPER_2 $delegation$DENOM --from $accounting_liquid -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-delegate-2 $accounting_liquid $delegation

    delegation_balance_pre_tokenize=$($CHAIN_BINARY q staking delegations $accounting_liquid --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
    val_liquid_1=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.liquid_shares')
    echo "validator liquid shares pre-tokenizing: $val_liquid_1"
    total_liquid_1=$($CHAIN_BINARY q staking total-liquid-staked -o json --home $HOME_1 | jq -r '.tokens')
    echo "total liquid shares pre-tokenizing: $total_liquid_1"
    tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.tokens')
    shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
    exchange_rate=$(echo "$shares/$tokens" | bc -l)
    expected_liquid_increase=$(echo "$exchange_rate*$tokenize" | bc -l)
    expected_liquid_increase=${expected_liquid_increase%.*}
    echo "Exchange rate: $exchange_rate, expected liquid increase: $expected_liquid_increase"

    echo "Tokenizing with accounting_liquid..."
    tests/v12_upgrade/log_lsm_data.sh accounting pre-tokenize-1 $accounting_liquid $tokenize
    submit_tx "tx staking tokenize-share $VALOPER_2 $tokenize$DENOM $accounting_liquid --from $accounting_liquid -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-tokenize-1 $accounting_liquid $tokenize
    val_liquid_2=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.liquid_shares')
    echo "validator liquid shares post-tokenizing: $val_liquid_2"
    total_liquid_2=$($CHAIN_BINARY q staking total-liquid-staked -o json --home $HOME_1 | jq -r '.tokens')
    echo "total liquid shares post-tokenizing: $total_liquid_2"
    val_delta=$(echo "$val_liquid_2-$val_liquid_1" | bc -l)
    val_delta=${val_delta%.*}
    total_delta=$(($total_liquid_2-$total_liquid_1))
    if [[ $val_delta -eq $expected_liquid_increase ]]; then
        echo "Accounting success: expected validator liquid shares increase ($val_delta = $expected_liquid_increase)"
    elif [[ $(($val_delta-$expected_liquid_increase)) -eq 1 ]]; then
        echo "Accounting success:  validator liquid shares increase off by 1"
    elif [[ $(($expected_liquid_increase-$val_delta)) -eq 1 ]]; then
        echo "Accounting success:  validator liquid shares increase off by 1"
    else
        echo "Accounting failure: unexpected validator liquid shares increase ($val_delta != $expected_liquid_increase)"
        exit 1
    fi
    if [[ $total_delta -eq $tokenize ]]; then
        echo "Accounting success: expected global liquid tokens increase ($total_delta = $tokenize)"
    elif [[ $(($total_delta-$tokenize)) -eq 1 ]]; then
        echo "Accounting success: global liquid tokens increase off by 1"
    elif [[ $(($tokenize-$total_delta)) -eq 1 ]]; then
        echo "Accounting success: global liquid tokens increase off by 1"
    else
        echo "Accounting failure: unexpected global liquid tokens increase ($total_delta != $tokenize)"
        exit 1
    fi

echo "** ACCOUNTING TESTS> 2: REDEEMING TOKENS DECREASES VALIDATOR LIQUID SHARES AND GLOBAL LIQUID STAKED TOKENS **"

    tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.tokens')
    shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
    exchange_rate=$(echo "$shares/$tokens" | bc -l)
    tokenized_balance=$($CHAIN_BINARY q bank balances $accounting_liquid --home $HOME_1 -o json | jq -r --arg DENOM "$tokenized_denom" '.balances[] | select(.denom==$DENOM).amount')
    echo "Tokenized balance: $tokenized_balance$tokenized_denom"

    expected_liquid_decrease=$(echo "$exchange_rate*$tokenize" | bc -l)
    expected_liquid_decrease=${expected_liquid_decrease%.*}
    echo "Exchange rate: $exchange_rate, expected liquid decrease: $expected_liquid_decrease"

    echo "Redeeming with tokenizing account..."
    tests/v12_upgrade/log_lsm_data.sh accounting pre-redeem-1 $accounting_liquid $tokenized_balance
    submit_tx "tx staking redeem-tokens $tokenized_balance$tokenized_denom --from $accounting_liquid -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-redeem-1 $accounting_liquid $tokenized_balance

    val_liquid_3=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.liquid_shares')
    echo "validator liquid shares post-redeem: $val_liquid_3"
    total_liquid_3=$($CHAIN_BINARY q staking total-liquid-staked -o json --home $HOME_1 | jq -r '.tokens')
    echo "total liquid shares post-redeem: $total_liquid_3"
    val_delta=$(echo "$val_liquid_2-$val_liquid_3" | bc -l)
    val_delta=${val_delta%.*}
    total_delta=$(($total_liquid_2-$total_liquid_3))
    if [[ $val_delta -eq $expected_liquid_decrease ]]; then
        echo "Accounting success: expected validator liquid shares decrease ($val_delta = $expected_liquid_decrease)"
    elif [[ $(($val_delta-$expected_liquid_decrease)) -eq 1 ]]; then
        echo "Accounting success:  validator liquid shares decrease off by 1"
    elif [[ $(($expected_liquid_increase-$val_delta)) -eq 1 ]]; then
        echo "Accounting success:  validator liquid shares decrease off by 1"
    else
        echo "Accounting failure: unexpected validator liquid shares decrease ($val_delta != $expected_liquid_decrease)"
        exit 1
    fi
    if [[ $total_delta -eq $tokenize ]]; then
        echo "Accounting success: expected global liquid tokens decrease ($total_delta = $tokenize)"
    elif [[ $(($total_delta-$tokenize)) -eq 1 ]]; then
        echo "Accounting success: global liquid tokens decrease off by 1"
    elif [[ $(($tokenize-$total_delta)) -eq 1 ]]; then
        echo "Accounting success: global liquid tokens decrease off by 1"
    else
        echo "Accounting failure: unexpected global liquid tokens decrease ($total_delta != $tokenize)"
        exit 1
    fi

echo "** ACCOUNTING TESTS> 3: ADDITIONAL DELEGATION INCREASES VALIDATOR BOND SHARES **"
    shares_1=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
    tokens_1=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.tokens')
    bond_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    exchange_rate_1=$(echo "$shares/$tokens" | bc -l)
    expected_shares_increase=$(echo "$delegation*$exchange_rate_1" | bc -l)
    expected_shares=$(echo "$expected_shares_increase+$bond_shares_1" | bc -l)
    expected_shares=${expected_shares%.*}

    tests/v12_upgrade/log_lsm_data.sh accounting pre-delegate-3 $accounting_bonding $delegation
    submit_tx "tx staking delegate $VALOPER_2 $delegation$DENOM --from $accounting_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-delegate-3 $accounting_bonding $delegation

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

echo "** ACCOUNTING TESTS> 4: UNBONDING DECREASES VALIDATOR BOND SHARES **"
    shares_1=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
    tokens_1=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.tokens')
    bond_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    exchange_rate_1=$(echo "$shares/$tokens" | bc -l)
    expected_shares_decrease=$(echo "$unbond*$exchange_rate_1" | bc -l)
    expected_shares=$(echo "$bond_shares_1-$expected_shares_decrease" | bc -l)
    expected_shares=${expected_shares%.*}

    tests/v12_upgrade/log_lsm_data.sh accounting pre-unbond-1 $accounting_bonding $delegation
    submit_tx "tx staking unbond $VALOPER_2 $unbond$DENOM --from $accounting_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-unbond-1 $accounting_bonding $delegation

    bond_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    bond_shares_2=${bond_shares_2%.*}
    echo "Validator 2 bond shares: $bond_shares_2, expected: $expected_shares"
    if [[ $bond_shares_2 -eq $expected_shares  ]]; then
        echo "Validator bond successful."
    elif [[ $(($bond_shares_2-$expected_shares)) -eq 1 ]]; then
        echo "Validator bond successful: bond shares decrease off by 1"
    elif [[ $(($expected_shares-$bond_shares_2)) -eq 1 ]]; then
        echo "Validator bond successful: bond shares decrease off by 1"
    else
        echo "Accounting failure: unexpected validator bond shares decrease ($bond_shares_2 != $expected_shares)"
        exit 1 
    fi

echo "** ACCOUNTING TESTS> 5: REDELEGATION INCREASES AND DECREASES VALIDATOR BOND SHARES **"
    tests/v12_upgrade/log_lsm_data.sh accounting pre-delegate-4 $accounting_bonding 50000000
    submit_tx "tx staking delegate $VALOPER_1 50000000$DENOM --from $accounting_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-delegate-4 $accounting_bonding 50000000

    tests/v12_upgrade/log_lsm_data.sh accounting pre-bond-2 $accounting_bonding -
    submit_tx "tx staking validator-bond $VALOPER_1 --from $accounting_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-bond-2 $accounting_bonding -

    shares_2_pre=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
    tokens_2_pre=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.tokens')
    bond_shares_2_pre=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    exchange_rate_2=$(echo "$shares_2_pre/$tokens_2_pre" | bc -l)
    expected_shares_decrease=$(echo "10000000*$exchange_rate_2" | bc -l)
    expected_shares_2=$(echo "$bond_shares_2_pre-$expected_shares_decrease" | bc -l)
    expected_shares_2=${expected_shares_2%.*}

    shares_1_pre=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
    tokens_1_pre=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.tokens')
    bond_shares_1_pre=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    exchange_rate_1=$(echo "$shares_1_pre/$tokens_1_pre" | bc -l)
    expected_shares_increase=$(echo "10000000*$exchange_rate_1" | bc -l)
    expected_shares_1=$(echo "$bond_shares_1_pre+$expected_shares_increase" | bc -l)
    expected_shares_1=${expected_shares_1%.*}

    tests/v12_upgrade/log_lsm_data.sh accounting pre-redelegate-1 $accounting_bonding 10000000
    submit_tx "tx staking redelegate $VALOPER_2 $VALOPER_1 10000000$DENOM --from $accounting_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-redelegate-1 $accounting_bonding 10000000

    bond_shares_2_post=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    bond_shares_2_post=${bond_shares_2_post%.*}
    echo "Validator 2 bond shares: $bond_shares_2_post, expected: $expected_shares_2"
    if [[ $bond_shares_2_post -eq $expected_shares_2  ]]; then
        echo "Validator bond successful."
    elif [[ $(($bond_shares_2_post-$expected_shares_2)) -eq 1 ]]; then
        echo "Validator bond successful: bond shares decrease off by 1"
    elif [[ $(($expected_shares_2-$bond_shares_2_post)) -eq 1 ]]; then
        echo "Validator bond successful: bond shares decrease off by 1"
    else
        echo "Accounting failure: unexpected validator bond shares decrease ($bond_shares_2_post != $expected_shares_2)"
        exit 1 
    fi

    bond_shares_1_post=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    bond_shares_1_post=${bond_shares_1_post%.*}
    echo "Validator 1 bond shares: $bond_shares_1_post, expected: $expected_shares_1"
    if [[ $bond_shares_1_post -eq $expected_shares_1  ]]; then
        echo "Validator bond successful."
    elif [[ $(($bond_shares_1_post-$expected_shares_1)) -eq 1 ]]; then
        echo "Validator bond successful: bond shares decrease off by 1"
    elif [[ $(($expected_shares_1-$bond_shares_1_post)) -eq 1 ]]; then
        echo "Validator bond successful: bond shares decrease off by 1"
    else
        echo "Accounting failure: unexpected validator bond shares decrease ($bond_shares_1_post != $expected_shares_1)"
        exit 1 
    fi

echo "** ACCOUNTING TESTS> CLEANUP **"
    delegation_balance=$($CHAIN_BINARY q staking delegations $accounting_bonding --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
    tests/v12_upgrade/log_lsm_data.sh accounting pre-unbond-2 $accounting_bonding $delegation_balance
    submit_tx "tx staking unbond $VALOPER_1 $delegation_balance$DENOM --from $accounting_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-unbond-2 $accounting_bonding $delegation_balance

    delegation_balance=$($CHAIN_BINARY q staking delegations $accounting_bonding --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
    tests/v12_upgrade/log_lsm_data.sh accounting pre-unbond-2 $accounting_bonding $delegation_balance
    submit_tx "tx staking unbond $VALOPER_2 $delegation_balance$DENOM --from $accounting_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-unbond-2 $accounting_bonding $delegation_balance

    delegation_balance=$($CHAIN_BINARY q staking delegations $accounting_liquid --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
    tests/v12_upgrade/log_lsm_data.sh accounting pre-unbond-3 $accounting_liquid $delegation_balance
    submit_tx "tx staking unbond $VALOPER_2 $delegation_balance$DENOM --from $accounting_liquid -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh accounting post-unbond-3 $accounting_liquid $delegation_balance

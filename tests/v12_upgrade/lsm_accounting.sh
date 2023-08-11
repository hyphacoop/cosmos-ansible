#!/bin/bash
# Implement accounting tests

source tests/process_tx.sh

delegation=20000000
tokenize=10000000
tokenized_denom=$VALOPER_2/4

# $CHAIN_BINARY keys add acct_bonding --home $HOME_1
$CHAIN_BINARY keys add acct_liquid --home $HOME_1

# bonding_address=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="acct_bonding").address')
liquid_address=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="acct_liquid").address')

# echo "Bonding address: $bonding_address"
echo "Liquid address 1: $liquid_address"

echo "Funding bonding and tokenizing accounts..."
# submit_tx "tx bank send $WALLET_1 $bonding_address  100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $liquid_address   100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1

# echo "Delegating with bonding_account..."
# submit_tx "tx staking delegate $VALOPER_2 $delegation$DENOM --from $bonding_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
# echo "Validator bond with bonding_account..."
# submit_tx "tx staking validator-bond $VALOPER_2 --from $bonding_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1

# validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.total_validator_bond_shares')
# echo "Validator 2 bond shares: $validator_bond_shares"
# if [[ ${validator_bond_shares%.*} -ne $delegation  ]]; then
#     echo "Validator bond unsuccessful."
#     exit 1
# fi

# ** Tokenization increases validator liquid shares and global liquid staked tokens **
echo "Delegating with tokenizing_account..."
submit_tx "tx staking delegate $VALOPER_2 $delegation$DENOM --from $liquid_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
delegation_balance_pre_tokenize=$($CHAIN_BINARY q staking delegations $liquid_address --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
val_liquid_1=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.total_liquid_shares')
echo "validator liquid shares pre-tokenizing: $val_liquid_1"
total_liquid_1=$($CHAIN_BINARY q staking total-liquid-staked -o json --home $HOME_1 | jq -r '.tokens')
echo "total liquid shares pre-tokenizing: $total_liquid_1"
tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.tokens')
shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
$CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.'
exchange_rate=$(echo "$shares/$tokens" | bc -l)
expected_liquid_increase=$(echo "$exchange_rate*$tokenize" | bc -l)
expected_liquid_increase=${expected_liquid_increase%.*}
echo "Exchange rate: $exchange_rate, expected liquid increase: $expected_liquid_increase"
echo "Tokenizing with tokenizing account..."
submit_tx "tx staking tokenize-share $VALOPER_2 $tokenize$DENOM $liquid_address --from $liquid_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
$CHAIN_BINARY q bank balances $liquid_address --home $HOME_1 -o json | jq '.'
val_liquid_2=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.total_liquid_shares')
echo "validator liquid shares post-tokenizing: $val_liquid_2"
# val_liquid_2=${val_liquid_2%.*}
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

tokens=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.tokens')
shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
$CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.'
exchange_rate=$(echo "$shares/$tokens" | bc -l)
expected_liquid_decrease=$(echo "$exchange_rate*$tokenize" | bc -l)
expected_liquid_decrease=${expected_liquid_decrease%.*}
echo "Exchange rate: $exchange_rate, expected liquid increase: $expected_liquid_decrease"
echo "Redeeming with tokenizing account..."
submit_tx "tx staking redeem-tokens $tokenize$tokenized_denom --from $liquid_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
val_liquid_3=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq -r '.total_liquid_shares')
echo "validator liquid shares post-redeem: $val_liquid_3"
# val_liquid_3=${val_liquid_3%.*}
total_liquid_3=$($CHAIN_BINARY q staking total-liquid-staked -o json --home $HOME_1 | jq -r '.tokens')
echo "total liquid shares post-redeem: $total_liquid_3"
val_delta=$(echo "$val_liquid_2-$val_liquid_3" | bc -l)
val_delta=${val_delta%.*}
total_delta=$(($total_liquid_2-$total_liquid_3))
if [[ $val_delta -eq $expected_liquid_decrease ]]; then
    echo "Accounting success: expected validator liquid shares increase ($val_delta = $expected_liquid_decrease)"
elif [[ $(($val_delta-$expected_liquid_decrease)) -eq 1 ]]; then
    echo "Accounting success:  validator liquid shares increase off by 1"
elif [[ $(($expected_liquid_increase-$val_delta)) -eq 1 ]]; then
    echo "Accounting success:  validator liquid shares increase off by 1"
else
    echo "Accounting failure: unexpected validator liquid shares increase ($val_delta != $expected_liquid_decrease)"
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

# echo "Unbonding from tokenizing account..."
# delegation_balance=$($CHAIN_BINARY q staking delegations $liquid_address --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
# submit_tx "tx staking unbond $VALOPER_2 ${delegation_balance%.*}$DENOM --from $liquid_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
# echo "Unbonding from bonding account..."
# delegation_balance=$($CHAIN_BINARY q staking delegations $bonding_address --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
# submit_tx "tx staking unbond $VALOPER_2 ${delegation_balance%.*}$DENOM --from $bonding_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
# $CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'

val1=$($CHAIN_BINARY q staking validator $VALOPER_1 -o json --home $HOME_1 | jq '.jailed')
val2=$($CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.jailed')
val3=$($CHAIN_BINARY q staking validator $VALOPER_3 -o json --home $HOME_1 | jq '.jailed')
echo "Validator jailed status: $val1 $val2 $val3"
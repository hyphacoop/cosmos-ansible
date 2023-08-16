#!/bin/bash

source tests/process_tx.sh
delegation=100000000
delegator_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
validator_bond_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')

echo "Delegating with $WALLET_2..."
submit_tx "tx staking delegate $VALOPER_1 $delegation$DENOM --from $WALLET_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

delegator_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
shares_diff=$((${delegator_shares_2%.*}-${delegator_shares_1%.*})) # remove decimal portion
echo "Delegator shares difference: $shares_diff"
if [[ $shares_diff -ne $delegation ]]; then
    echo "Delegation unsuccessful."
    exit 1
fi

$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'

echo "Validator bond with $WALLET_2..."
submit_tx "tx staking validator-bond $VALOPER_1 --from $WALLET_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1

validator_bond_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
bond_shares_diff=$((${validator_bond_shares_2%.*}-${validator_bond_shares_1%.*})) # remove decimal portion
echo "Bond shares difference: $bond_shares_diff"
if [[ $shares_diff -ne $delegation  ]]; then
    echo "Validator bond unsuccessful."
    exit 1
fi

$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
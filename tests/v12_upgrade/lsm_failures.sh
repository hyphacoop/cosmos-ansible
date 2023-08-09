#!/bin/bash

source tests/process_tx.sh
delegation=100000000
delegator_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
validator_bond_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.total_validator_bond_shares')

echo "Attempt to tokenize with $WALLET_4..."
submit_bad_tx "tx staking tokenize-share $VALOPER_1 20000000$DENOM $WALLET_4 --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

$CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.'
$CHAIN_BINARY q staking delegations $WALLET_4 --home $HOME_1 -o json | jq -r '.'
$CHAIN_BINARY q bank balances $WALLET_4 --home $HOME_1 -o json | jq -r '.'

# echo "Validator bond with $WALLET_2..."
# submit_tx "tx staking validator-bond $VALOPER_1 --from $WALLET_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1

# validator_bond_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.total_validator_bond_shares')
# bond_shares_diff=$((${validator_bond_shares_2%.*}-${validator_bond_shares_1%.*})) # remove decimal portion
# echo "Bond shares difference: $bond_shares_diff"
# if [[ $shares_diff -ne $delegation  ]]; then
#     echo "Validator bond unsuccessful."
#     exit 1
# fi
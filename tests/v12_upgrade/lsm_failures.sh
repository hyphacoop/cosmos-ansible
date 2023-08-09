#!/bin/bash

source tests/process_tx.sh

validator_cap_param=$($CHAIN_BINARY q staking params --home $HOME_1 -o json | jq -r '.validator_liquid_staking_cap')
global_cap_param=$($CHAIN_BINARY q staking params --home $HOME_1 -o json | jq -r '.global_liquid_staking_cap')

echo "Delegating with WALLET_5..."
submit_tx "tx staking delegate $VALOPER_1 120000000$DENOM --from $WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

echo "Failure case 1: Attempt to tokenize with WALLET_4 (no validator bond)..."
submit_bad_tx "tx staking tokenize-share $VALOPER_1 20000000$DENOM $WALLET_4 --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

echo "Failure case 2: Attempt to tokenize bond delegations with WALLET_4..."
submit_tx "tx staking validator-bond $VALOPER_1 --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1
validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.total_validator_bond_shares')
echo "Validator bond shares: ${validator_bond_shares%.*}"
if [[ ${validator_bond_shares%.*} -ne 20000000  ]]; then
    echo "Validator bond unsuccessful."
    exit 1
fi
submit_bad_tx "tx staking tokenize-share $VALOPER_1 20000000$DENOM $WALLET_4 --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

bonded_tokens=$($CHAIN_BINARY q staking pool --home $HOME_1 -o json | jq -r '.bonded_tokens')
validator_delegations=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
cap_per_validator=$(($bonded_tokens*$validator_cap_param))
glabl_cap=$(($bonded_tokens*$global_cap_param))
echo "Validator shares cap: $cap_per_validator"
echo "Global shares cap: $global_cap"

echo "Failure case 3: Attempt to tokenize with WALLET_5, breaching the validator liquid staking cap..."
submit_bad_tx "tx staking tokenize-share $VALOPER_1 120000000$DENOM $WALLET_5 --from $WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

echo "Failure case 4: Attempt to tokenize with $WALLET_5, breaching the global liquid staking cap..."
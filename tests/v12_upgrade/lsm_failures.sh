#!/bin/bash

source tests/process_tx.sh

wallet_4_delegations=20000000
wallet_5_delegations=150000000

validator_cap_param=$($CHAIN_BINARY q staking params --home $HOME_1 -o json | jq -r '.validator_liquid_staking_cap')
global_cap_param=$($CHAIN_BINARY q staking params --home $HOME_1 -o json | jq -r '.global_liquid_staking_cap')

echo "Delegating with WALLET_4..."
submit_tx "tx staking delegate $VALOPER_1 $wallet_4_delegations$DENOM --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
submit_tx "tx staking delegate $VALOPER_2 $wallet_4_delegations$DENOM --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

echo "Delegating with WALLET_5..."
submit_tx "tx staking delegate $VALOPER_1 $wallet_5_delegations$DENOM --from $WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
submit_tx "tx staking delegate $VALOPER_2 $wallet_5_delegations$DENOM --from $WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

echo "Failure case 1: Attempt to tokenize with WALLET_4 (no validator bond)..."
submit_bad_tx "tx staking tokenize-share $VALOPER_1 20000000$DENOM $WALLET_4 --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

submit_tx "tx staking validator-bond $VALOPER_1 --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1
submit_tx "tx staking validator-bond $VALOPER_2 --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1
validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.total_validator_bond_shares')
echo "Validator 1 bond shares: ${validator_bond_shares%.*}"
if [[ ${validator_bond_shares%.*} -ne $wallet_4_delegations  ]]; then
    echo "Validator bond unsuccessful."
    exit 1
fi
validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.total_validator_bond_shares')
echo "Validator 2 bond shares: ${validator_bond_shares%.*}"
if [[ ${validator_bond_shares%.*} -ne $wallet_4_delegations  ]]; then
    echo "Validator bond unsuccessful."
    exit 1
fi

echo "Failure case 2: Attempt to tokenize bond delegations with WALLET_4..."
submit_bad_tx "tx staking tokenize-share $VALOPER_1 $wallet_4_delegations$DENOM $WALLET_4 --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

validator_delegations=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
validator_cap=$(echo "$validator_delegations*$validator_cap_param" | bc)
echo "Validator_delegations: ${validator_delegations%.*}"
echo "Validator shares cap: ${validator_cap%.*}"

echo "Failure case 3: Attempt to tokenize with WALLET_5, breaching the validator liquid staking cap..."
submit_bad_tx "tx staking tokenize-share $VALOPER_1 100000000$DENOM $WALLET_5 --from $WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

bonded_tokens=$($CHAIN_BINARY q staking pool --home $HOME_1 -o json | jq -r '.bonded_tokens')
global_staked=$($CHAIN_BINARY q staking total-liquid-staked --home $HOME_1 -o json | jq -r '.')
global_cap=$(echo "$bonded_tokens*$global_cap_param" | bc)
echo "Global shares cap: ${global_cap%.*}"
echo "Global staked: $global_staked"

echo "Failure case 4: Attempt to tokenize with $WALLET_5, breaching the global liquid staking cap..."
submit_tx "tx staking tokenize-share $VALOPER_1 120000000$DENOM $WALLET_5 --from $WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
submit_bad_tx "tx staking tokenize-share $VALOPER_2 20000000$DENOM $WALLET_5 --from $WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
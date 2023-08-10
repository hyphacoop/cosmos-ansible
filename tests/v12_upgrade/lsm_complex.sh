#!/bin/bash
# Implement complex user flows involving slashed validators
# Scenario 1: delegate - tokenize - slash - redeem
# Scenario 2: delegate - slash - tokenize - redeem

source tests/process_tx.sh

delegation=10000000
tokenize=50000000
tokenized_denom=$VALOPER_2/1
delegator_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')

echo "Delegating with WALLET_4..."
submit_tx "tx staking delegate $VALOPER_2 $delegation$DENOM --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
echo "Validator bond with WALLET 4..."
submit_tx "tx staking validator-bond $VALOPER_2 --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1

validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.total_validator_bond_shares')
echo "Validator 2 bond shares: $validator_bond_shares"
if [[ $validator_bond_shares -ne $delegation  ]]; then
    echo "Validator bond unsuccessful."
    exit 1
fi

$CHAIN_BINARY q bank balances $WALLET_4 -o json | jq '.'

# delegator_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
# shares_diff=$((${delegator_shares_2%.*}-${delegator_shares_1%.*})) # remove decimal portion
# echo "Delegator shares difference: $shares_diff"
# if [[ $shares_diff -ne $delegation ]]; then
#     echo "Delegation unsuccessful."
#     exit 1
# fi

# echo "Tokenizing shares with $WALLET_3..."
# submit_tx "tx staking tokenize-share $VALOPER_1 $tokenize$DENOM $WALLET_3 --from $WALLET_3 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

# liquid_shares=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.total_liquid_shares')
# echo "Liquid shares: ${liquid_shares%.*}"
# if [[ ${liquid_shares%.*} -ne $tokenize ]]; then
#     echo "Tokenize unsuccessful: unexpected liquid shares amount"
#     exit 1
# fi

# liquid_balance=$($CHAIN_BINARY q bank balances $WALLET_3 --home $HOME_1 -o json | jq -r --arg DENOM "$tokenized_denom" '.balances[] | select(.denom==$DENOM).amount')
# echo "Liquid balance: ${liquid_balance%.*}"
# if [[ ${liquid_balance%.*} -ne $tokenize ]]; then
#     echo "Tokenize unsuccessful: unexpected liquid token balance"
#     exit 1
# fi
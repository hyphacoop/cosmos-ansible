#!/bin/bash
# Implement complex user flows involving slashed validators
# Scenario 1: delegate - tokenize - slash - redeem
# Scenario 2: delegate - slash - tokenize - redeem

source tests/process_tx.sh

delegation=10000000
tokenize=10000000
# tokenized_denom=$VALOPER_2/1
delegator_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')

$CHAIN_BINARY keys add bonding_account --home $HOME_1
$CHAIN_BINARY keys add liquid_account --home $HOME_1
bonding_address=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="bonding_account").address')
liquid_address=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="liquid_account").address')

echo "Funding bonding and tokenizing accounts..."
submit_tx "tx bank send $WALLET_1 $bonding_address 100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $liquid_address 100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1

# ** SCENARIO 1 **

echo "Delegating with bonding_account..."
submit_tx "tx staking delegate $VALOPER_2 $delegation$DENOM --from bonding_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
echo "Validator bond with bonding_account..."
submit_tx "tx staking validator-bond $VALOPER_2 --from bonding_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1

validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.total_validator_bond_shares')
echo "Validator 2 bond shares: $validator_bond_shares"
if [[ ${validator_bond_shares%.*} -ne $delegation  ]]; then
    echo "Validator bond unsuccessful."
    exit 1
fi

$CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'

echo "Delegating with tokenizing_account..."
submit_tx "tx staking delegate $VALOPER_2 $delegation$DENOM --from liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
echo "Tokenizing with tokenizing account..."
submit_tx "tx staking tokenize-share $VALOPER_2 $tokenize$DENOM $liquid_address --from liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

$CHAIN_BINARY q bank balances $liquid_address -o json --home $HOME_1 | jq '.'

# echo "Redeeming with tokenizing account..."
# submit_tx "tx staking redeem-tokens $tokenize$tokenized_denom --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -b block -y" $CHAIN_BINARY $HOME_1

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
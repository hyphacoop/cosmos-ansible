#!/bin/bash
# Implement accounting tests

source tests/process_tx.sh

delegation=20000000
tokenize=10000000
tokenized_denom=$VALOPER_2/1

$CHAIN_BINARY keys add acct_bonding --home $HOME_1
$CHAIN_BINARY keys add acct_liquid --home $HOME_1

bonding_address=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="acct_bonding").address')
liquid_address=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="acct_liquid").address')

echo "Bonding address: $bonding_address"
echo "Liquid address 1: $liquid_address"

echo "Funding bonding and tokenizing accounts..."
submit_tx "tx bank send $WALLET_1 $bonding_address  100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $liquid_address   100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1

echo "Delegating with bonding_account..."
submit_tx "tx staking delegate $VALOPER_2 $delegation$DENOM --from $bonding_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
echo "Validator bond with bonding_account..."
submit_tx "tx staking validator-bond $VALOPER_2 --from $bonding_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1

validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.total_validator_bond_shares')
echo "Validator 2 bond shares: $validator_bond_shares"
if [[ ${validator_bond_shares%.*} -ne $delegation  ]]; then
    echo "Validator bond unsuccessful."
    exit 1
fi

# ** Tokenization increases validator liquid shares and global liquid staked tokens **
echo "Delegating with tokenizing_account..."
submit_tx "tx staking delegate $VALOPER_2 $delegation$DENOM --from $liquid_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
delegation_balance_pre_tokenize=$($CHAIN_BINARY q staking delegations $liquid_address_1 --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q staking total-liquid-staked -o json --home $HOME_1 | jq '.'
echo "Tokenizing with tokenizing account..."
submit_tx "tx staking tokenize-share $VALOPER_2 $tokenize$DENOM $liquid_address --from $liquid_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q staking total-liquid-staked -o json --home $HOME_1 | jq '.'
echo "Redeeming with tokenizing account..."
submit_tx "tx staking redeem-tokens $tokenize$tokenized_denom --from $liquid_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
delegation_balance_post_redeem=$($CHAIN_BINARY q staking delegations $liquid_address --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
$CHAIN_BINARY q staking validator $VALOPER_2 -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q staking total-liquid-staked -o json --home $HOME_1 | jq '.'

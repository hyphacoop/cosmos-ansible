#!/bin/bash
# Implement complex user flows involving slashed validators
# Scenario 1: delegate - tokenize - slash - redeem
# Scenario 2: delegate - slash - tokenize - redeem

source tests/process_tx.sh

delegation=20000000
tokenize=10000000
tokenized_denom=$VALOPER_2/1

$CHAIN_BINARY keys add bonding_account --home $HOME_1
$CHAIN_BINARY keys add liquid_account --home $HOME_1
bonding_address=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="bonding_account").address')
liquid_address=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="liquid_account").address')

echo "Funding bonding and tokenizing accounts..."
submit_tx "tx bank send $WALLET_1 $bonding_address 100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $liquid_address 100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1

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

# ** SCENARIO 1 **
echo "** SCENARIO 1: delegate - tokenize - slash - redeem **"
echo "Delegating with tokenizing_account..."
submit_tx "tx staking delegate $VALOPER_2 $tokenize$DENOM --from liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
delegation_balance_pre_tokenize=$($CHAIN_BINARY q staking delegations $liquid_address --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
slash_fraction=$($CHAIN_BINARY q slashing params --home $HOME_1 -o json | jq -r '.slash_fraction_downtime')
expected_balance=$(echo "$delegation_balance_pre_tokenize-($delegation_balance_pre_tokenize*$slash_fraction)" | bc)
echo "Tokenizing with tokenizing account..."
submit_tx "tx staking tokenize-share $VALOPER_2 $tokenize$DENOM $liquid_address --from liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
echo "Slashing validator 2..."
tests/major_fresh_upgrade/jail_validator.sh $PROVIDER_SERVICE_2 $VALOPER_2
echo "Redeeming with tokenizing account..."
submit_tx "tx staking redeem-tokens $tokenize$tokenized_denom --from liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
delegation_balance_post_redeem=$($CHAIN_BINARY q staking delegations $liquid_address --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
echo "New balance: $delegation_balance_post_redeem"
echo "Expected new balance: $expected_balance"
if [[ $delegation_balance_post_redeem -ne ${expected_balance%.*} ]]; then
    echo "Complex scenario 1 failed: Unexpected post-redeem balance ($delegation_balance_post_redeem)"
    exit 1
fi

echo "Unjailing validator 2..."
tests/major_fresh_upgrade/unjail_validator.sh $PROVIDER_SERVICE_2 $VAL2_RPC_PORT $WALLET_2 $VALOPER_2
$CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'

echo "Unbonding from tokenizing account..."
sumbit_tx "tx staking unbond $VALOPER_2 $tokenize$DENOM --from liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
$CHAIN_BINARY q staking delegations $liquid_address --home $HOME_1 -o json | jq '.'

# ** SCENARIO 2 **
echo "** SCENARIO 2: delegate - slash - tokenize - redeem **"
echo "Delegating with tokenizing_account..."
submit_tx "tx staking delegate $VALOPER_2 $tokenize$DENOM --from liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
$CHAIN_BINARY q staking delegations $liquid_address --home $HOME_1 -o json | jq '.'
delegation_balance_pre_tokenize=$($CHAIN_BINARY q staking delegations $liquid_address --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
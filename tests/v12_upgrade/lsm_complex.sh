#!/bin/bash
# Implement complex user flows involving slashed validators
# Scenario 1: delegate - tokenize - slash - redeem
# Scenario 2: delegate - slash - tokenize - redeem

source tests/process_tx.sh

delegation=20000000
tokenize=10000000
tokenized_denom_1=$VALOPER_2/2
tokenized_denom_2=$VALOPER_2/3

$CHAIN_BINARY keys add bonding_account --home $HOME_1
$CHAIN_BINARY keys add liquid_account_1 --home $HOME_1
$CHAIN_BINARY keys add liquid_account_2 --home $HOME_1

bonding_address=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="bonding_account").address')
liquid_address_1=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="liquid_account_1").address')
liquid_address_2=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="liquid_account_2").address')
echo "Bonding address: $bonding_address"
echo "Liquid address 1: $liquid_address_1"
echo "Liquid address 2: $liquid_address_2"

echo "Funding bonding and tokenizing accounts..."
submit_tx "tx bank send $WALLET_1 $bonding_address  100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $liquid_address_1 100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $liquid_address_2 100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1

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
submit_tx "tx staking delegate $VALOPER_2 $tokenize$DENOM --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
delegation_balance_pre_tokenize=$($CHAIN_BINARY q staking delegations $liquid_address_1 --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
slash_fraction=$($CHAIN_BINARY q slashing params --home $HOME_1 -o json | jq -r '.slash_fraction_downtime')
expected_balance=$(echo "$delegation_balance_pre_tokenize-($delegation_balance_pre_tokenize*$slash_fraction)" | bc)
echo "Tokenizing with tokenizing account..."
submit_tx "tx staking tokenize-share $VALOPER_2 $tokenize$DENOM $liquid_address_1 --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
echo "Slashing validator 2..."
tests/major_fresh_upgrade/jail_validator.sh $PROVIDER_SERVICE_2 $VALOPER_2
echo "Redeeming with tokenizing account..."
submit_tx "tx staking redeem-tokens $tokenize$tokenized_denom_1 --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
delegation_balance_post_redeem=$($CHAIN_BINARY q staking delegations $liquid_address_1 --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
echo "New balance: $delegation_balance_post_redeem"
echo "Expected new balance: ${expected_balance%.*}"

if [[ $delegation_balance_post_redeem -ne ${expected_balance%.*} ]]; then
    echo "Complex scenario 1 failed: Unexpected post-redeem balance ($delegation_balance_post_redeem)"
    exit 1
else
    echo "Complex scenario 1 passed".
fi

echo "Unjailing validator 2..."
tests/major_fresh_upgrade/unjail_validator.sh $PROVIDER_SERVICE_2 $VAL2_RPC_PORT $WALLET_2 $VALOPER_2
# $CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'
# echo "Unbonding from tokenizing account..."
# submit_tx "tx staking unbond $VALOPER_2 ${delegation_balance_post_redeem%.*}$DENOM --from $liquid_address_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
# echo "Unbonding from bonding account..."
# delegation_balance=$($CHAIN_BINARY q staking delegations $bonding_address --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
# submit_tx "tx staking unbond $VALOPER_2 ${delegation_balance%.*}$DENOM --from $bonding_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

$CHAIN_BINARY q staking delegations $bonding_address --home $HOME_1 -o json | jq '.'
$CHAIN_BINARY q staking delegations-to $VALOPER_2 --home $HOME_1 -o json | jq '.'
$CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'

# ** SCENARIO 2 **
echo "** SCENARIO 2: delegate - slash - tokenize - redeem **"
# echo "Delegating with bonding_account..."
# submit_tx "tx staking delegate $VALOPER_2 $delegation$DENOM --from $bonding_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
# echo "Validator bond with bonding_account..."
# submit_tx "tx staking validator-bond $VALOPER_2 --from $bonding_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1

# $CHAIN_BINARY q staking delegations $bonding_address --home $HOME_1 -o json | jq '.'
# $CHAIN_BINARY q staking delegations-to $VALOPER_2 --home $HOME_1 -o json | jq '.'
# $CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'

echo "Delegating with tokenizing_account..."
submit_tx "tx staking delegate $VALOPER_2 $tokenize$DENOM --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

$CHAIN_BINARY q staking delegations $bonding_address --home $HOME_1 -o json | jq '.'
$CHAIN_BINARY q staking delegations-to $VALOPER_2 --home $HOME_1 -o json | jq '.'
$CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'

echo "Slashing validator 2..."
tests/major_fresh_upgrade/jail_validator.sh $PROVIDER_SERVICE_2 $VALOPER_2
downtime_period=$($CHAIN_BINARY q slashing params --home $HOME_1 -o json | jq -r '.downtime_jail_duration')
sleep ${downtime_period%?}
echo "Unjailing validator 2..."
tests/major_fresh_upgrade/unjail_validator.sh $PROVIDER_SERVICE_2 $VAL2_RPC_PORT $WALLET_2 $VALOPER_2
delegation_balance_pre_tokenize=$($CHAIN_BINARY q staking delegations $liquid_address_2 --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')

$CHAIN_BINARY q staking delegations $bonding_address --home $HOME_1 -o json | jq '.'
$CHAIN_BINARY q staking delegations-to $VALOPER_2 --home $HOME_1 -o json | jq '.'
$CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'

echo "Tokenizing with tokenizing account..."
submit_tx "tx staking tokenize-share $VALOPER_2 $delegation_balance_pre_tokenize$DENOM $liquid_address_2 --from liquid_account_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
echo "Redeeming with tokenizing account..."
submit_tx "tx staking redeem-tokens $delegation_balance_pre_tokenize$tokenized_denom_2 --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
delegation_balance_post_redeem=$($CHAIN_BINARY q staking delegations $liquid_address_2 --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
echo "Balance: $delegation_balance_post_redeem"
echo "Expected balance: $delegation_balance_pre_tokenize"
if [[ $delegation_balance_pre_tokenize -eq $delegation_balance_post_redeem ]]; then
    echo "Complex scenario 2 passed"
elif [[ $(($delegation_balance_pre_tokenize-$delegation_balance_post_redeem)) -eq 1 ]]; then
    echo "Complex scenario 2 passed: post-redeem balance is 1$DENOM less than pre-tokenization balance ($delegation_balance_post_redeem < $delegation_balance_pre_tokenize)"
elif [[ $(($delegation_balance_post_redeem-$delegation_balance_pre_tokenize)) -eq 1 ]]; then
    echo "Complex scenario 2 passed: post-redeem balance is 1$DENOM more than pre-tokenization balance ($delegation_balance_post_redeem > $delegation_balance_pre_tokenize)"
else
    echo "Complex scenario 2 failed: Unexpected post-redeem balance ($delegation_balance_post_redeem)"
    exit 1
fi

echo "Unbonding from tokenizing account..."
submit_tx "tx staking unbond $VALOPER_2 ${delegation_balance_post_redeem%.*}$DENOM --from $liquid_address_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1
# echo "Unbonding from bonding account..."
# delegation_balance=$($CHAIN_BINARY q staking delegations $bonding_address --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
# submit_tx "tx staking unbond $VALOPER_2 ${delegation_balance%.*}$DENOM --from bonding_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -y" $CHAIN_BINARY $HOME_1

$CHAIN_BINARY q staking delegations-to $VALOPER_2 --home $HOME_1 -o json | jq '.'
$CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'
#!/bin/bash
flow=$1
action=$2
account=$3
amount=$4

# Log LSM events:
# action, account, amount, val1 tokens, val1 shares, val1 bond shares, val1 liquid shares, val2 tokens, val2 shares, val2 bond shares, val2 liquid shares
val1_data=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json)
val1_tokens=$(echo $val1_data | jq -r '.tokens')
val1_shares=$(echo $val1_data | jq -r '.delegator_shares')
val1_bond_shares=$(echo $val1_data | jq -r '.validator_bond_shares')
val1_liquid_shares=$(echo $val1_data | jq -r '.liquid_shares')

if [ $VALOPER_2 ]; then
    val2_data=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json)
    val2_tokens=$(echo $val2_data | jq -r '.tokens')
    val2_shares=$(echo $val2_data | jq -r '.delegator_shares')
    val2_bond_shares=$(echo $val2_data | jq -r '.validator_bond_shares')
    val2_liquid_shares=$(echo $val2_data | jq -r '.liquid_shares')
fi
acct_balances=$($CHAIN_BINARY q bank balances $account --home $HOME_1 -o json)
acct_delegations=$($CHAIN_BINARY q staking delegations $account --home $HOME_1 -o json)

balance=$(echo $acct_balances | jq -r '.balances[0].amount')$(echo $acct_balance | jq -r '.balances[0].denom')
del_shares=$(echo $acct_delegations | jq -r '.delegation_responses[0].delegation.shares')
del_balance=$(echo $acct_delegations | jq -r '.delegation_responses[0].balance.amount')$(echo $acct_delegations | jq -r '.delegation_responses[0].balance.denom')

echo "$flow,$action,$account,$amount,$balance,$del_shares,$del_balance,$val1_tokens,$val1_shares,$val1_bond_shares,$val1_liquid_shares,$val2_tokens,$val2_shares,$val2_bond_shares,$val2_liquid_shares" >> lsm_log.csv
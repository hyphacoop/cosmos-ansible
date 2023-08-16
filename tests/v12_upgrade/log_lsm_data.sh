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

val2_data=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json)
val2_tokens=$(echo $val2_data | jq -r '.tokens')
val2_shares=$(echo $val2_data | jq -r '.delegator_shares')
val2_bond_shares=$(echo $val2_data | jq -r '.validator_bond_shares')
val2_liquid_shares=$(echo $val2_data | jq -r '.liquid_shares')

echo "$flow,$action,$account,$amount,$val1_tokens,$val1_shares,$val1_bond_shares,$val1_liquid_shares,$val2_tokens,$val2_shares,$val2_bond_shares,$val2_liquid_shares" >> $LSM_LOG
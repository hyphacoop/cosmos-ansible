#!/bin/bash

acc_type=$(gaiad --home $HOME_1 q account cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 --height $post_upgrade_height -o json | jq -r '."@type"')

# Check if account type matches
echo "Account type is: $acc_type"
if [ "$acc_type" != "/cosmos.vesting.v1beta1.ContinuousVestingAccount" ]; then
    echo "Account is not a vesting account"
    exit 1
fi


# Get spendable balances 1
spendable_balance1=$(gaiad --home $HOME_1 q bank spendable-balances cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 -o json | jq -r '.balances[] | select(.denom == "uatom") | .amount')
echo "Current spendable balance is: $spendable_balance1"

# Wait for 5 blocks
tests/test_block_production.sh 127.0.0.1 $VAL1_RPC_PORT 5

# Get spendable balances 2
spendable_balance2=$(gaiad --home $HOME_1 q bank spendable-balances cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 -o json | jq -r '.balances[] | select(.denom == "uatom") | .amount')
echo "Current spendable balance is: $spendable_balance2"

# Check if spendable balance matches
if [ $spendable_balance2 -gt $spendable_balance1 ]; then
    echo "Spendable balance increased balance 1 is: $spendable_balance1, balance 2 is: $spendable_balance2"
else
    echo "Spendable balance did not increase, spendable balance 1 is: $spendable_balance1, balance 2 is: $spendable_balance2"
    exit 2
fi

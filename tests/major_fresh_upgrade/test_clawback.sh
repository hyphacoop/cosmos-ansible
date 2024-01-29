#!/bin/bash

# Get upgrade height
upgrade_height=$(gaiad --home $HOME_1 q upgrade applied v15 -o json | jq -r '.header.height')

# Set heights
let pre_upgrade_height=$upgrade_height-1
let post_upgrade_height=$upgrade_height+1

# Get account type from pre-upgrade and post-upgrade heights
pre_upgrade_acc_type=$(gaiad --home $HOME_1 q account cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 --height $pre_upgrade_height -o json | jq -r '."@type"')
post_upgrade_acc_type=$(gaiad --home $HOME_1 q account cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 --height $post_upgrade_height -o json | jq -r '."@type"')

# Check if account type matches
echo "Pre upgrade account type is: $pre_upgrade_acc_type"
if [ "$pre_upgrade_acc_type" != "/cosmos.vesting.v1beta1.ContinuousVestingAccount" ]; then
    echo "Pre upgrade account is not a vesting account"
    exit 1
fi

echo "Post upgrade account type is: $post_upgrade_acc_type"
if [ "$post_upgrade_acc_type" != "/cosmos.auth.v1beta1.BaseAccount" ]; then
    echo "Post upgrade account is not a base account"
    exit 2
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
if [ $spendable_balance1 -ne $spendable_balance2 ]; then
    echo "Spendable balance 1 is: $spendable_balance1 balance 2 is: $spendable_balance2"
    exit 3
else
    echo "Spendable balance unchanged as expected, spendable balance 1 is: $spendable_balance1 balance 2 is: $spendable_balance2"
fi

# Check bank balances
echo "Before upgrade"
gaiad --home $HOME_1 q bank spendable-balances cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 --height $pre_upgrade_height

echo "After upgrade"
gaiad --home $HOME_1 q bank spendable-balances cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 --height $post_upgrade_height

# Check community pool
echo "Before upgrade"
gaiad  --home $HOME_1 q distribution community-pool --height $pre_upgrade_height

echo "Before upgrade"
gaiad  --home $HOME_1 q distribution community-pool --height $post_upgrade_height
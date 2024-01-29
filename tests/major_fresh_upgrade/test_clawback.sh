#!/bin/bash

# Get upgrade height
upgrade_height=$(gaiad --home $HOME_1 q upgrade applied v15 -o json | jq -r '.header.height')

# Set heights
let pre_upgrade_height=$upgrade_height-1
let post_upgrade_height=$upgrade_height+1

# Get account type from pre-upgrade and post-upgrade heights
pre_upgrade_acc_type=$(gaiad --home $HOME_1 q account cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 --height $pre_upgrade_height -o json | jq -r '."@type"')
post_upgrade_acc_type=$(gaiad --home $HOME_1 q account cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 --height $post_upgrade_height -o json | jq -r '."@type"')
pre_upgrade_acc2_type=$(gaiad --home $HOME_1 q account cosmos1n7qdtcnagfvs8p4t537c5yn2dylw2e7l7a2htm --height $pre_upgrade_height -o json | jq -r '."@type"')
post_upgrade_acc2_type=$(gaiad --home $HOME_1 q account cosmos1n7qdtcnagfvs8p4t537c5yn2dylw2e7l7a2htm --height $post_upgrade_height -o json | jq -r '."@type"')

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

# Check if account type matches
echo "Pre upgrade account2 type is: $pre_upgrade_acc_type"
if [ "$pre_upgrade_acc2_type" != "/cosmos.vesting.v1beta1.ContinuousVestingAccount" ]; then
    echo "Pre upgrade account is not a vesting account"
    exit 3
fi

echo "Post upgrade account type is: $post_upgrade_acc_type"
if [ "$post_upgrade_acc2_type" != "/cosmos.vesting.v1beta1.ContinuousVestingAccount" ]; then
    echo "Post upgrade account is not a vesting account, this account's type shouldn't change"
    exit 4
fi

# Check spendable balances for cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 is not incresing
echo "Check spendable balances for cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 is not incresing"
# Get spendable balances 1
spendable_balance1_acc=$(gaiad --home $HOME_1 q bank spendable-balances cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 -o json | jq -r '.balances[] | select(.denom == "uatom") | .amount')
echo "Current spendable balance is: $spendable_balance1_acc"

# Wait for 5 blocks
tests/test_block_production.sh 127.0.0.1 $VAL1_RPC_PORT 5

# Get spendable balances 2
spendable_balance2_acc=$(gaiad --home $HOME_1 q bank spendable-balances cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 -o json | jq -r '.balances[] | select(.denom == "uatom") | .amount')
echo "Current spendable balance is: $spendable_balance2_acc"

# Check if spendable balance matches
if [ $spendable_balance1_acc -ne $spendable_balance2_acc ]; then
    echo "Spendable balance 1 is: $spendable_balance1_acc balance 2 is: $spendable_balance2_acc"
    exit 5
else
    echo "Spendable balance unchanged as expected, spendable balance 1 is: $spendable_balance1_acc balance 2 is: $spendable_balance2_acc"
fi

# Check spendable balances for cosmos1n7qdtcnagfvs8p4t537c5yn2dylw2e7l7a2htm is incresing
echo "Check spendable balances for cosmos1n7qdtcnagfvs8p4t537c5yn2dylw2e7l7a2htm is incresing"
# Get spendable balances 1
spendable_balance1_acc2=$(gaiad --home $HOME_1 q bank spendable-balances cosmos1n7qdtcnagfvs8p4t537c5yn2dylw2e7l7a2htm -o json | jq -r '.balances[] | select(.denom == "uatom") | .amount')
echo "Current spendable balance is: $spendable_balance1_acc2"

# Wait for 5 blocks
tests/test_block_production.sh 127.0.0.1 $VAL1_RPC_PORT 5

# Get spendable balances 2
spendable_balance2_acc2=$(gaiad --home $HOME_1 q bank spendable-balances cosmos1n7qdtcnagfvs8p4t537c5yn2dylw2e7l7a2htm -o json | jq -r '.balances[] | select(.denom == "uatom") | .amount')
echo "Current spendable balance is: $spendable_balance2_acc2"

# Check if spendable balance matches
if [ $spendable_balance1_acc2 -ne $spendable_balance2_acc2 ]; then
    echo "Spendable balance 1 is: $spendable_balance1_acc2 balance 2 is: $spendable_balance2_acc2"
else
    echo "Spendable unchanged, spendable balance 1 is: $spendable_balance1_acc2 balance 2 is: $spendable_balance2_acc2"
    exit 6
fi

# Check bank balances
echo "Before upgrade"
gaiad --home $HOME_1 q bank spendable-balances cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 --height $pre_upgrade_height

echo "After upgrade"
gaiad --home $HOME_1 q bank spendable-balances cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 --height $post_upgrade_height

# Check community pool
echo "Before upgrade"
gaiad  --home $HOME_1 q distribution community-pool --height $pre_upgrade_height

echo "After upgrade"
gaiad  --home $HOME_1 q distribution community-pool --height $post_upgrade_height

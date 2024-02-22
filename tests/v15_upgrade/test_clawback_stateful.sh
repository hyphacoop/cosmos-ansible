#!/bin/bash

# set -e

# Get upgrade height and time
upgrade_height=$($CHAIN_BINARY --home $HOME_1 q upgrade applied v15 -o json | jq -r '.header.height')
upgrade_time=$($CHAIN_BINARY --home $HOME_1 q upgrade applied v15 -o json | jq -r '.header.time')

# Set heights
let pre_upgrade_height=$upgrade_height-1
let post_upgrade_height=$upgrade_height+1

# Get account type from pre-upgrade and post-upgrade heights
pre_upgrade_acc_type=$($CHAIN_BINARY --home $HOME_1 q account $CB_ACCT --height $pre_upgrade_height -o json | jq -r '."@type"')
post_upgrade_acc_type=$($CHAIN_BINARY --home $HOME_1 q account $CB_ACCT --height $post_upgrade_height -o json | jq -r '."@type"')

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

echo "Spendable balances for $CB_ACCT must not increase."
# Get spendable balances 1
spendable_balance1_acc=$(gaiad --home $HOME_1 q bank spendable-balances $CB_ACCT -o json | jq -r '.balances[] | select(.denom == "uatom") | .amount')
echo "Current spendable balance is: $spendable_balance1_acc"

sleep $VOTING_PERIOD

# Check bank balances
echo "Spendable balances acc 1"
echo "Before upgrade"
$CHAIN_BINARY --home $HOME_1 q bank spendable-balances $CB_ACCT --height $pre_upgrade_height

echo "After upgrade"
$CHAIN_BINARY --home $HOME_1 q bank spendable-balances $CB_ACCT --height $post_upgrade_height


# Set the block time
vesting_block_time="2023-03-14T20:07:23Z"
vesting_epoch=$(date -d "$vesting_block_time" +%s)
upgrade_epoch=$(date -d "$upgrade_time" +%s)

echo "Vesting account started at: $vesting_block_time epoch: $vesting_epoch"
echo "upgrade time: $upgrade_time epoch: $upgrade_epoch"

# Calculate vesting duration
vesting_duration=$(echo "$VESTING_TARGET-$vesting_epoch" | bc -l)
echo "Total vesting duration: $vesting_duration"

# Calculate elapsed vesting
vesting_elapsed=$(echo "$upgrade_epoch-$vesting_epoch" | bc -l)
echo "Elapsed vesting: $vesting_elapsed"

# Calculate vesting amount
vesting_div=$(echo "$vesting_elapsed/$vesting_duration" | bc -l)
vested=$(echo "(120000000000*$vesting_div)+0.5" | bc -l)

vested=${vested%.*} # remove decimals
spendable_balance1_acc=${spendable_balance1_acc%.*} # remove decimals
zero_diff=$(echo "$vested - $spendable_balance1_acc" | bc -l)
# if [[ "$zero_diff" == "0" ]]; then
#     echo "PASS: Unvested amount turned into spendable balance."
# else
#     echo "FAIL: Unvested amount does not equal spendable balance."
#     exit 1
# fi

# Check community pool
pre_upgrade_cp=$($CHAIN_BINARY --home $HOME_1 q distribution community-pool --height $pre_upgrade_height -o json | jq -r '.pool[] | select(.denom == "uatom") | .amount')
echo "Community pool balance before upgrade: $pre_upgrade_cp"

post_upgrade_cp=$($CHAIN_BINARY --home $HOME_1 q distribution community-pool --height $post_upgrade_height -o json | jq -r '.pool[] | select(.denom == "uatom") | .amount')
echo "Community pool balance after upgrade: $post_upgrade_cp"

cp_diff=$(echo "$post_upgrade_cp-$pre_upgrade_cp" | bc -l)
unvested=$(echo "120000000000-$vested" | bc -l)
echo "Unvested amount: $unvested, community pool increase: $cp_diff."

echo "Vested amount: $vested, spendable balance is $spendable_balance1_acc."

echo "TEST: Community pool increase must be at least as much as the unvested amount."
cp_unvested_diff=$(echo "$cp_diff - $unvested" | bc -l)
if [[ "$cp_unvested_diff" > "0" ]]; then
    echo "PASS: Community pool increased by at least the unvested amount."
else
    echo "FAIL: Community pool did not increase by at least the unvested amount." 
    exit 1
fi

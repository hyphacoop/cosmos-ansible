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
pre_upgrade_acc2_type=$($CHAIN_BINARY --home $HOME_1 q account $V_ACCT --height $pre_upgrade_height -o json | jq -r '."@type"')
post_upgrade_acc2_type=$($CHAIN_BINARY --home $HOME_1 q account $V_ACCT --height $post_upgrade_height -o json | jq -r '."@type"')

# Check if account type matches
echo "Pre upgrade account type is: $pre_upgrade_acc_type"
if [ "$pre_upgrade_acc_type" != "/cosmos.vesting.v1beta1.ContinuousVestingAccount" ]; then
    echo "Pre upgrade account is not a vesting account"
    exit 1
fi

echo "Post upgrade account type is: $post_upgrade_acc2_type"
if [ "$post_upgrade_acc_type" != "/cosmos.auth.v1beta1.BaseAccount" ]; then
    echo "Post upgrade account is not a base account"
    exit 2
fi

# Check if account type matches
echo "Pre upgrade account2 type is: $pre_upgrade_acc2_type"
if [ "$pre_upgrade_acc2_type" != "/cosmos.vesting.v1beta1.ContinuousVestingAccount" ]; then
    echo "Pre upgrade account is not a vesting account"
    exit 3
fi

echo "Post upgrade account2 type is: $post_upgrade_acc2_type"
if [ "$post_upgrade_acc2_type" != "/cosmos.vesting.v1beta1.ContinuousVestingAccount" ]; then
    echo "Post upgrade account is not a vesting account, this account's type shouldn't change"
    exit 4
fi

echo "Spendable balances for $CB_ACCT must not increase."
# Get spendable balances 1
spendable_balance1_acc=$(gaiad --home $HOME_1 q bank spendable-balances $CB_ACCT -o json | jq -r '.balances[] | select(.denom == "uatom") | .amount')
echo "Current spendable balance is: $spendable_balance1_acc"

echo "Spendable balances for $V_ACCT must increase."
# Get spendable balances 1
spendable_balance1_acc2=$(gaiad --home $HOME_1 q bank spendable-balances $V_ACCT -o json | jq -r '.balances[] | select(.denom == "uatom") | .amount')
echo "Current spendable balance is: $spendable_balance1_acc2"

sleep $VOTING_PERIOD

# Get spendable balances 2
spendable_balance2_acc=$(gaiad --home $HOME_1 q bank spendable-balances $CB_ACCT -o json | jq -r '.balances[] | select(.denom == "uatom") | .amount')
echo "Current spendable balance is: $spendable_balance2_acc"

# Check if spendable balance matches
if [ $spendable_balance1_acc -ne $spendable_balance2_acc ]; then
    echo "Spendable balance 1 is: $spendable_balance1_acc balance 2 is: $spendable_balance2_acc"
    exit 5
else
    echo "Spendable balance unchanged as expected, spendable balance 1 is: $spendable_balance1_acc balance 2 is: $spendable_balance2_acc"
fi

# Get spendable balances 2
spendable_balance2_acc2=$(gaiad --home $HOME_1 q bank spendable-balances $V_ACCT -o json | jq -r '.balances[] | select(.denom == "uatom") | .amount')
echo "Current spendable balance is: $spendable_balance2_acc2"

# Check if spendable balance matches
if [ $spendable_balance1_acc2 -ne $spendable_balance2_acc2 ]; then
    echo "Spendable balance 1 is: $spendable_balance1_acc2 balance 2 is: $spendable_balance2_acc2"
else
    echo "Spendable unchanged, spendable balance 1 is: $spendable_balance1_acc2 balance 2 is: $spendable_balance2_acc2"
    exit 6
fi

# Check bank balances
echo "Spendable balances acc 1"
echo "Before upgrade"
$CHAIN_BINARY --home $HOME_1 q bank spendable-balances $CB_ACCT --height $pre_upgrade_height

echo "After upgrade"
$CHAIN_BINARY --home $HOME_1 q bank spendable-balances $CB_ACCT --height $post_upgrade_height

echo "Spendable balances acc 2"
echo "Before upgrade"
$CHAIN_BINARY --home $HOME_1 q bank spendable-balances $V_ACCT --height $pre_upgrade_height

echo "After upgrade"
$CHAIN_BINARY --home $HOME_1 q bank spendable-balances $V_ACCT --height $post_upgrade_height

# get the block time of the tx for the vesting account
vesting_txhash=$(echo $TX_VESTING_ACC_TX_JSON | jq -r .txhash)
echo "Vesting  account create txhash: $vesting_txhash"
vesting_height=$(gaiad --home $HOME_1 q tx $vesting_txhash -o json | jq -r '.height')
echo "Vesting height: $vesting_height"
vesting_block_time=$(gaiad --home $HOME_1 q block $vesting_height | jq -r '.block.header.time')
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
vested=$(echo "(100000000*$vesting_div)+0.5" | bc -l)

vested=${vested%.*} # remove decimals
spendable_balance1_acc=${spendable_balance1_acc%.*} # remove decimals
echo "Vested amount: $vested, spendable balance is $spendable_balance1_acc."
zero_diff=$(echo "$vested - $spendable_balance1_acc" | bc -l)
if [[ "$zero_diff" == "0" ]]; then
    echo "PASS: Unvested amount turned into spendable balance."
else
    echo "FAIL: Unvested amount does not equal spendable balance."
    exit 1
fi

# Check community pool
pre_upgrade_cp=$($CHAIN_BINARY --home $HOME_1 q distribution community-pool --height $pre_upgrade_height -o json | jq -r '.pool[] | select(.denom == "uatom") | .amount')
echo "Community pool balance before upgrade: $pre_upgrade_cp"

post_upgrade_cp=$($CHAIN_BINARY --home $HOME_1 q distribution community-pool --height $post_upgrade_height -o json | jq -r '.pool[] | select(.denom == "uatom") | .amount')
echo "Community pool balance after upgrade: $post_upgrade_cp"

cp_diff=$(echo "$post_upgrade_cp-$pre_upgrade_cp" | bc -l)
unvested=$(echo "100000000-$vested" | bc -l)
echo "Unvested amount: $unvested, community pool increase: $cp_diff."

echo "TEST: Community pool increase must be at least as much as the unvested amount."
cp_unvested_diff=$(echo "$cp_diff - $unvested" | bc -l)
if [[ "$cp_unvested_diff" > "0" ]]; then
    echo "PASS: Community pool increased by at least the unvested amount."
else
    echo "FAIL: Community pool did not increase by at least the unvested amount." 
    exit 1
fi

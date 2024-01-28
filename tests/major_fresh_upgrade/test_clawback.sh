#!/bin/bash

# Get upgrade height
upgrade_height=$(gaiad --home $HOME_1 q upgrade applied v15 -o json | jq -r '.header.height')

let pre_upgrade_height=$upgrade_height-1
let post_upgrade_height=$upgrade_height+1

pre_upgrade_acc_type=$(gaiad --home $HOME_1 q account cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 --height $pre_upgrade_height -o json | jq -r '."@type"')
post_upgrade_acc_type=$(gaiad --home $HOME_1 q account cosmos145hytrc49m0hn6fphp8d5h4xspwkawcuzmx498 --height $post_upgrade_height -o json | jq -r '."@type"')

echo "Pre upgrade account type is: pre_upgrade_acc_type"
if [ "$pre_upgrade_acc_type" != "/cosmos.vesting.v1beta1.ContinuousVestingAccount" ]; then
    echo "Pre upgrade account is not a vesting account"
    exit 1
fi

echo "Post upgrade account type is: post_upgrade_acc_type"
if [ "$post_upgrade_acc_type" != "/cosmos.auth.v1beta1.BaseAccount" ]; then
    echo "Post upgrade account is not a base account"
    exit 2
fi

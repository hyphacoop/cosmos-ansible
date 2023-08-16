#!/bin/bash

source tests/process_tx.sh

bank_send_amount=20000000
ibc_transfer_amount=10000000
tokenized_denom="$VALOPER_1/1"

wallet_3_delegations_1=$($CHAIN_BINARY q staking delegations $WALLET_3 --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).delegation.shares')
echo "Wallet_3 delegations: $wallet_3_delegations_1"

$CHAIN_BINARY keys add liquid_account --home $HOME_1
liquid_address=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="liquid_account").address')
echo "Liquid address 1: $liquid_address"

echo "Funding liquid account..."
submit_tx "tx bank send $WALLET_1 $liquid_address 100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1

echo "Sending tokens from WALLET_3 to liquid_address via bank send..."
submit_tx "tx bank send $WALLET_3 $liquid_address $bank_send_amount$tokenized_denom --from $WALLET_3 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -b block -y" $CHAIN_BINARY $HOME_1
# sleep 2
echo "Sending tokens from $WALLET_3 to WALLET_5 via ibc transfer..."
submit_ibc_tx "tx ibc-transfer transfer transfer $IBC_CHANNEL $STRIDE_WALLET_5 $ibc_transfer_amount$tokenized_denom --from $WALLET_3 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -b block -y" $CHAIN_BINARY $HOME_1
# echo "Waiting for IBC tokens to reach $STRIDE_CHAIN_ID..."
# sleep 20
ibc_denom=ibc/$($STRIDE_CHAIN_BINARY q ibc-transfer denom-hash transfer/channel-1/$tokenized_denom --home $STRIDE_HOME_1 -o json | jq -r '.hash')
ibc_balance=$($STRIDE_CHAIN_BINARY q bank balances $STRIDE_WALLET_5 --home $STRIDE_HOME_1 -o json | jq -r --arg DENOM "$ibc_denom" '.balances[] | select(.denom==$DENOM).amount')
echo "IBC-wrapped liquid token balance: $ibc_balance$ibc_denom"
if [[ $ibc_balance -ne $ibc_transfer_amount ]]; then
    echo "Tokenize unsuccessful: unexpected ibc-wrapped liquid token balance"
    exit 1
fi

$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
$CHAIN_BINARY q bank balances $WALLET_3 -o json --home $HOME_1 | jq '.'
echo "Redeeming tokens from WALLET_3..."
submit_tx "tx staking redeem-tokens 20000000$tokenized_denom --from $WALLET_3 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -b block -y" $CHAIN_BINARY $HOME_1
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
echo "Redeeming tokens from liquid_address..."
submit_tx "tx staking redeem-tokens $bank_send_amount$tokenized_denom --from $liquid_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -b block -y" $CHAIN_BINARY $HOME_1
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'

echo "Transferring $WALLET_5 IBC tokens to LSM chain with..."
echo "IBC denom: $ibc_denom"
echo "Sending tokens from $WALLET_5 to $CHAIN_ID for redeem operation..."
submit_ibc_tx "tx ibc-transfer transfer transfer channel-1 $WALLET_5 $ibc_transfer_amount$ibc_denom --from $STRIDE_WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $CONSUMER_FEES$STRIDE_DENOM -y" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
# echo "Waiting for IBC tokens to reach $CHAIN_ID..."
# sleep 10
echo "Redeeming tokens from $WALLET_5..."
submit_tx "tx staking redeem-tokens $ibc_transfer_amount$tokenized_denom --from $WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -b block -y" $CHAIN_BINARY $HOME_1

wallet_3_delegations_2=$($CHAIN_BINARY q staking delegations $WALLET_3 --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).delegation.shares')
wallet_3_delegations_diff=$((${wallet_3_delegations_2%.*}-${wallet_3_delegations_1%.*}))
liquid_acct_delegations=$($CHAIN_BINARY q staking delegations $liquid_address --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).delegation.shares')
# wallet_5_delegations=$($CHAIN_BINARY q staking delegations $WALLET_5 --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).delegation.shares')
wallet_3_delegation_balance=$($CHAIN_BINARY q staking delegations $WALLET_3 --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).balance.amount')
liquid_acct_delegation_balance=$($CHAIN_BINARY q staking delegations $liquid_address --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).balance.amount')
# wallet_5_delegation_balance=$($CHAIN_BINARY q staking delegations $WALLET_5 --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).balance.amount')
# validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
# validator_liquid_shares=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.liquid_shares')
# $CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json

echo "Wallet 3 delegation shares increase: $wallet_3_delegations_diff"
if [[ $wallet_3_delegations_diff -ne 20000000 ]]; then
    echo "Redeem unsuccessful: unexpected delegation shares for wallet 3"
    exit 1
fi

echo "Wallet 3 delegation balance: $wallet_3_delegation_balance"
if [[ $wallet_3_delegation_balance -ne 70000000 ]]; then
    echo "Redeem unsuccessful: unexpected delegation balance for wallet 3"
    exit 1
fi

echo "Wallet 4 delegation shares: ${liquid_acct_delegations%.*}"
if [[ ${liquid_acct_delegations%.*} -ne $bank_send_amount ]]; then
    echo "Redeem unsuccessful: unexpected delegation shares for wallet 4"
    exit 1
fi

echo "Wallet 4 delegation balance: $liquid_acct_delegation_balance"
if [[ $liquid_acct_delegation_balance -ne $bank_send_amount ]]; then
    echo "Redeem unsuccessful: unexpected delegation balance for wallet 4"
    exit 1
fi

# echo "Wallet 5 delegation shares: ${wallet_5_delegations%.*}"
# if [[ ${wallet_5_delegations%.*} -ne $ibc_transfer_amount ]]; then
#     echo "Redeem unsuccessful: unexpected delegation shares for wallet 5"
#     exit 1
# fi

# echo "Wallet 5 delegation balance: $wallet_5_delegation_balance"
# if [[ $wallet_5_delegation_balance -ne $ibc_transfer_amount ]]; then
#     echo "Redeem unsuccessful: unexpected delegation balance for wallet 5"
#     exit 1
# fi

# echo "Validator bond shares: ${validator_bond_shares%.*}"
# if [[ ${validator_bond_shares%.*} -ne 100000000  ]]; then
#     echo "Redeem unsuccessful: unexpected validator bond shares amount"
#     exit 1
# fi

# echo "Validator liquid shares: ${validator_liquid_shares%.*}"
# if [[ ${validator_liquid_shares%.*} -ne 0  ]]; then
#     echo "Redeem unsuccessful: unexpected validator liquid shares amount"
#     exit 1
# fi

echo "Validator unbond from WALLET_2..."
submit_tx "tx staking unbond $VALOPER_1 100000000$DENOM --from $WALLET_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1
validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
echo "Validator bond shares: ${validator_bond_shares%.*}"
if [[ ${validator_bond_shares%.*} -ne 0  ]]; then
    echo "Unbond unsuccessful: unexpected validator bond shares amount"
    exit 1
fi

$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'

echo "Validator unbond from WALLET_3..."
submit_tx "tx staking unbond $VALOPER_1 70000000$DENOM --from $WALLET_3 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1
validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
echo "Validator bond shares: ${validator_bond_shares%.*}"
if [[ ${validator_bond_shares%.*} -ne 0  ]]; then
    echo "Unbond unsuccessful: unexpected validator bond shares amount"
    exit 1
fi

$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'

echo "Validator unbond from liquid_address..."
submit_tx "tx staking unbond $VALOPER_1 $bank_send_amount$DENOM --from $liquid_address -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --fees $BASE_FEES$DENOM" $CHAIN_BINARY $HOME_1
validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
echo "Validator bond shares: ${validator_bond_shares%.*}"
if [[ ${validator_bond_shares%.*} -ne 0  ]]; then
    echo "Unbond unsuccessful: unexpected validator bond shares amount"
    exit 1
fi

sleep $(($COMMIT_TIMEOUT+2))
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
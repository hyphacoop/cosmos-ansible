#!/bin/bash

source tests/process_tx.sh

bank_send_amount=20000000
ibc_transfer_amount=10000000
tokenized_denom="$VALOPER_1/1"

echo "Sending tokens from $WALLET_3 to $WALLET_4 via bank send..."
submit_tx "tx bank send $WALLET_3 $WALLET_4 $bank_send_amount$tokenized_denom --from $WALLET_3 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -b block -y" $CHAIN_BINARY $HOME_1
# sleep 2
echo "Sending tokens from $WALLET_3 to $WALLET_5 via ibc transfer..."
submit_tx "tx ibc-transfer transfer transfer channel-1 $STRIDE_WALLET_5 $ibc_transfer_amount$tokenized_denom --from $WALLET_3 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -b block -y" $CHAIN_BINARY $HOME_1
echo "Waiting for IBC tokens to reach $STRIDE_CHAIN_ID..."
sleep 20
# $STRIDE_CHAIN_BINARY q bank balances $STRIDE_WALLET_5 --home $STRIDE_HOME_1 -o json
ibc_denom=ibc/$($STRIDE_CHAIN_BINARY q ibc-transfer denom-hash transfer/channel-1/$tokenized_denom --home $STRIDE_HOME_1 -o json | jq -r '.hash')

ibc_balance=$($STRIDE_CHAIN_BINARY q bank balances $STRIDE_WALLET_5 --home $STRIDE_HOME_1 -o json | jq -r --arg DENOM "$ibc_denom" '.balances[] | select(.denom==$DENOM).amount')
echo "IBC-wrapped liquid token balance: $ibc_balance"
if [[ $ibc_balance -ne $ibc_transfer_amount ]]; then
    echo "Tokenize unsuccessful: unexpected ibc-wrapped liquid token balance"
    exit 1
fi

$CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.'
echo "Redeeming tokens from $WALLET_3..."
submit_tx "tx staking redeem-tokens 20000000$tokenized_denom --from $WALLET_3 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -b block -y" $CHAIN_BINARY $HOME_1
$CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.'
echo "Redeeming tokens from $WALLET_4..."
submit_tx "tx staking redeem-tokens 20000000$tokenized_denom --from $WALLET_4 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -b block -y" $CHAIN_BINARY $HOME_1
$CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.'
echo "Transferring $WALLET_5 IBC tokens to LSM chain with..."
echo "IBC denom: $ibc_denom"
echo "Sending tokens from $WALLET_5 to $CHAIN_ID for redeem operation..."
submit_tx "tx ibc-transfer transfer transfer channel-1 $WALLET_5 10000000$ibc_denom --from $STRIDE_WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $CONSUMER_FEES$STRIDE_DENOM -y" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
echo "Waiting for IBC tokens to reach $CHAIN_ID..."
sleep 10
echo "Redeeming tokens from $WALLET_5..."
submit_tx "tx staking redeem-tokens 10000000$tokenized_denom --from $WALLET_5 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -b block -y" $CHAIN_BINARY $HOME_1
$CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.'


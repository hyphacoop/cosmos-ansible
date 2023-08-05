#!/bin/bash

tokenized_denom="$VALOPER_1/1"

echo "Sending tokens from $WALLET_3 to $WALLET_4 via bank send..."
$CHAIN_BINARY tx bank send $WALLET_3 $WALLET_4 20000000$tokenized_denom --from $WALLET_3 -o json --home $HOME_1 --gas auto --gas-adjustment 1.2  --fees $BASE_FEES$DENOM -b block -y | jq '.'
sleep 2
echo "Sending tokens from $WALLET_3 to $WALLET_5 via ibc transfer..."
$CHAIN_BINARY tx ibc-transfer transfer transfer channel-1 $WALLET_5 10000000$tokenized_denom --from $WALLET_3 -o json --home $HOME_1 --gas auto --gas-adjustment 1.2  --fees $BASE_FEES$DENOM -b block -y | jq '.'
sleep 2

echo "Redeeming tokens from $WALLET_3..."
$CHAIN_BINARY tx staking redeem-tokens 20000000$tokenized_denom --from $WALLET_3 --home $HOME_1 -o json --gas auto --gas-adjustment --fees $BASE_FEES$DENOM -b block -y | jq '.'
echo "Redeeming tokens from $WALLET_4..."
$CHAIN_BINARY tx staking redeem-tokens 20000000$tokenized_denom --from $WALLET_4 --home $HOME_1 -o json --gas auto --gas-adjustment --fees $BASE_FEES$DENOM -b block -y | jq '.'
echo "Transferring $WALLET_5 IBC tokens to LSM chain with..."
ibc_denom=ibc/$($CONSUMER_CHAIN_BINARY q ibc-transfer denom-hash transfer/channel-1/$tokenized_denom --home ~/.cona1 -o json | jq -r '.hash')
echo "IBC denom: $ibc_denom"
$CONSUMER_CHAIN_BINARY tx ibc-transfer transfer transfer channel-1 $WALLET_5 10000000$tokenized_denom --from $WALLET_3 -o json --home $HOME_1 --gas auto --gas-adjustment 1.2  --fees $CONSUMER_FEES$DENOM -b block -y | jq '.'
echo "Redeeming tokens from $WALLET_5..."
$CHAIN_BINARY tx staking redeem-tokens 10000000$tokenized_denom --from $WALLET_5 --home $HOME_1 -o json --gas auto --gas-adjustment --fees $BASE_FEES$DENOM -b block -y | jq '.'

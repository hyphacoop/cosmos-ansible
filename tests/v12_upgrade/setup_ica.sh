#!/bin/bash

echo "Registering ICA account..."
$STRIDE_CHAIN_BINARY tx interchain-accounts controller register connection-0 --from $STRIDE_WALLET_1 --gas auto --gas-adjustment 1.2 --fees $BASE_FEES$STRIDE_DENOM -y --home $STRIDE_HOME_1 --chain-id $STRIDE_CHAIN_ID -o json | jq '.'
sleep 30
ica_address=$($STRIDE_CHAIN_BINARY q interchain-accounts controller interchain-account $STRIDE_WALLET_1 connection-0 --home $STRIDE_HOME_1 -o json | jq -r '.address')
echo "ICA address: $ica_address"
echo "Funding ICA address in chain $CHAIN_ID..."
$CHAIN_BINARY tx bank send $WALLET_2 $ica_address 1000000000$DENOM --gas auto --gas-adjustment 1.2 --fees $BASE_FEES$DENOM -b block -y --home $HOME_1 -o json | jq '.'
$CHAIN_BINARY q bank balances $ica_address --home $HOME_1 -o json | jq '.'

echo "Saving the ICA address...\n"
echo "ICA_ADDRESS=$ica_address" >> $GITHUB_ENV
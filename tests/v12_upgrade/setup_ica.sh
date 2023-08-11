#!/bin/bash
source tests/process_tx.sh

echo "Registering ICA account..."
submit_ibc_tx "tx interchain-accounts controller register connection-0 --from $STRIDE_WALLET_1 --gas auto --gas-adjustment 1.2 --fees $BASE_FEES$STRIDE_DENOM -y --chain-id $STRIDE_CHAIN_ID -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
# $STRIDE_CHAIN_BINARY tx interchain-accounts controller register connection-0 --from $STRIDE_WALLET_1 --gas auto --gas-adjustment 1.2 --fees $BASE_FEES$STRIDE_DENOM -y --home $STRIDE_HOME_1 --chain-id $STRIDE_CHAIN_ID -o json | jq '.'
# sleep 10
ica_address=$($STRIDE_CHAIN_BINARY q interchain-accounts controller interchain-account $STRIDE_WALLET_1 connection-0 --home $STRIDE_HOME_1 -o json | jq -r '.address')
echo "ICA address: $ica_address"
echo "Funding ICA address in chain $CHAIN_ID..."
submit_tx "tx bank send $WALLET_1 $ica_address 1000000000$DENOM --gas auto --gas-adjustment 1.2 --fees $BASE_FEES$DENOM -b block -y -o json" $CHAIN_BINARY $HOME_1
# $CHAIN_BINARY tx bank send $WALLET_1 $ica_address 1000000000$DENOM --gas auto --gas-adjustment 1.2 --fees $BASE_FEES$DENOM -b block -y --home $HOME_1 -o json | jq '.'
$CHAIN_BINARY q bank balances $ica_address --home $HOME_1 -o json | jq '.'

echo "Saving the ICA address..."
echo "ICA_ADDRESS=$ica_address" >> $GITHUB_ENV
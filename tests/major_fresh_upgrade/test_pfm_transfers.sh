#!/bin/bash

# Get channel from provider
$CHAIN_BINARY q ibc client states --home $HOME_1


# client_provider=$(hermes --json query clients --host-chain $CHAIN_ID | grep result | jq -r '.result[] | select(.chain_id=="pfm1").client_id')
client_provider=$($CHAIN_BINARY q ibc client states --output json --home $HOME_1 | jq -r '.client_states[] | select(.client_state.chain_id == "pfm1").client_id')
echo "Provider chain client ID: $client_provider"
connection_provider=$($CHAIN_BINARY q ibc connection connections --home $HOME_1 -o json | jq -r --arg CLIENT "$client_provider" '.connections[] | select(.client_id==$CLIENT).id')
echo "Provider chain connection ID: $connection_provider"
channel_provider=$($CHAIN_BINARY q ibc channel channels --home $HOME_1 -o json | jq -r --arg CONNECTION "$connection_provider" '.channels[] | select(.connection_hops[0]==$CONNECTION).channel_id')
echo "Provider chain channel ID: $channel_provider"

# provider -> channel-0 chain a -> channel-0 chain b -> channel-0 chain c
target_denom_a_d=ibc/$(echo -n transfer/channel-0/transfer/channel-0/transfer/channel-0/uatom | shasum -a 256 | cut -d ' ' -f1 | tr '[a-z]' '[A-Z]')
# chain c -> channel-1 chain b -> channel-1 chain a -> channel-X provider
target_denom_d_a=ibc/$(echo -n transfer/$channel_provider/transfer/channel-1/transfer/channel-1/uatom | shasum -a 256 | cut -d ' ' -f1 | tr '[a-z]' '[A-Z]')
echo "Target denom A->D: $target_denom_a_d"
echo "Target denom D->A: $target_denom_d_a"

$CHAIN_BINARY tx ibc-transfer transfer transfer $channel_provider "pfm" --memo "{\"forward\": {\"receiver\": \"pfm\",\"port\": \"transfer\",\"channel\": \"channel-1\",\"timeout\": \"10m\",\"next\": {\"forward\": {\"receiver\": \"$WALLET_1\",\"port\": \"transfer\",\"channel\":\"channel-1\",\"timeout\":\"10m\"}}}}" 1000000$DENOM --from $WALLET_1 --gas auto --gas-prices 0.005$DENOM --gas-adjustment $GAS_ADJUSTMENT -y --home $HOME_1
# command="$CHAIN_BINARY tx ibc-transfer transfer transfer $channel_provider \"pfm\" 1000000$DENOM --memo \"{\\\"forward\\\": {\\\"receiver\\\": \\\"pfm\\\",\\\"port\\\": \\\"transfer\\\",\\\"channel\\\": \\\"channel-1\\\",\\\"timeout\\\": \\\"10m\\\",\\\"next\\\": {\\\"forward\\\": {\\\"receiver\\\": \\\"$WALLET_1\\\",\\\"port\\\": \\\"transfer\\\",\\\"channel\\\":\\\"channel-1\\\",\\\"timeout\\\":\\\"10m\\\"}}}}\" --from $WALLET_1 --gas auto --gas-prices 0.005$DENOM --gas-adjustment $GAS_ADJUSTMENT -y --home $HOME_1 -o json"
# echo $command
# TXHASH=$($command | jq -r '.txhash')
sleep 6
# $CHAIN_BINARY q tx $TXHASH --home $HOME_1

$CHAIN_BINARY tx ibc-transfer transfer transfer channel-0 "pfm" --memo "{\"forward\": {\"receiver\": \"pfm\",\"port\": \"transfer\",\"channel\": \"channel-0\",\"timeout\": \"10m\",\"next\": {\"forward\": {\"receiver\": \"$WALLET_1\",\"port\": \"transfer\",\"channel\":\"channel-0\",\"timeout\":\"10m\"}}}}" 1000000$DENOM --from $WALLET_1 --gas auto --gas-prices 0.005$DENOM --gas-adjustment $GAS_ADJUSTMENT -y --home $PFM_HOME
# command="$CHAIN_BINARY tx ibc-transfer transfer transfer channel-0 \"pfm\" --memo \"{\"forward\": {\"receiver\": \"pfm\",\"port\": \"transfer\",\"channel\": \"channel-0\",\"timeout\": \"10m\",\"next\": {\"forward\": {\"receiver\": \"$WALLET_1\",\"port\": \"transfer\",\"channel\":\"channel-0\",\"timeout\":\"10m\"}}}}\" 1000000$DENOM --from $WALLET_1 --gas auto --gas-prices 0.005$DENOM --gas-adjustment $GAS_ADJUSTMENT -y --home $PFM_HOME"
# TXHASH=$($command | jq -r '.txhash')
# sleep 6
# $CHAIN_BINARY q tx $TXHASH --home $PFM_HOME
sleep 30

$CHAIN_BINARY q bank balances $WALLET_1 --home $PFM_HOME
$CHAIN_BINARY q bank balances $WALLET_1 --home $HOME_1

ibc_amount_a_d=$($CHAIN_BINARY q bank balances $WALLET_1 --home $PFM_HOME -o json | jq -r --arg DENOM "$target_denom_a_d" '.balances[] | select(.denom == $DENOM).amount')
ibc_amount_d_a=$($CHAIN_BINARY q bank balances $WALLET_1 --home $HOME_1 -o json | jq -r --arg DENOM "$target_denom_d_a" '.balances[] | select(.denom == $DENOM).amount')
echo "IBC amount provider -> pfm2: $ibc_amount_a_d"
echo "IBC amount pfm2 -> provider: $ibc_amount_d_a"


if [ ! -z $ibc_amount_a_d ] ; then
    echo "PFM A->D: PASS"
else
    echo "PFM A->D: FAIL"
    exit 1
fi

if [ ! -z $ibc_amount_d_a ] ; then
    echo "PFM D->A: PASS"
else
    echo "PFM D->A: FAIL"
    exit 1
fi

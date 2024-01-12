#!/bin/bash
# Test IBC transfer

echo "Running with $CONSUMER_CHAIN_BINARY."

PROVIDER_CHANNEL=$1
EXPECTED_DENOMS=$2
PROVIDER_WALLET=$3
CONSUMER_WALLET=$4

if [ ! $PROVIDER_WALLET ]
then
    PROVIDER_WALLET=$WALLET_1
fi

if [ ! $CONSUMER_WALLET ]
then
    CONSUMER_WALLET=$WALLET_1
fi

# Transfer provider token to consumer chain
echo "Current $CONSUMER_CHAIN_ID bank blances: $CONSUMER_WALLET"
$CONSUMER_CHAIN_BINARY --home $CONSUMER_HOME_1 q bank balances $CONSUMER_WALLET
echo "Sending $DENOM to $CONSUMER_CHAIN_ID..."
$CHAIN_BINARY --home $HOME_1 tx ibc-transfer transfer transfer $PROVIDER_CHANNEL $CONSUMER_WALLET 1000$DENOM --from $PROVIDER_WALLET --keyring-backend test --gas 500000 --fees 5000$DENOM -b sync -y --chain-id $CHAIN_ID
echo "Waiting for the transfer to reach the consumer chain..."
sleep 60
echo "$CONSUMER_CHAIN_ID bank blances after sending: $CONSUMER_WALLET"
$CONSUMER_CHAIN_BINARY --home $CONSUMER_HOME_1 q bank balances $CONSUMER_WALLET
DENOM_AMOUNT=$($CONSUMER_CHAIN_BINARY --home $CONSUMER_HOME_1 q bank balances $CONSUMER_WALLET -o json | jq -r '.balances | length')
if [ $DENOM_AMOUNT -lt 2 ]; then
    echo "Only one denom found in consumer wallet."
    exit 1
fi
echo "Found at least two denoms in the consumer wallet."

# Transfer consumer token to provider chain
echo "Current $CHAIN_ID bank blances: $PROVIDER_WALLET"
$CHAIN_BINARY --home $HOME_1 q bank balances $PROVIDER_WALLET
echo "Sending $CONSUMER_DENOM to $CHAIN_ID..."
$CONSUMER_CHAIN_BINARY --home $CONSUMER_HOME_1 tx ibc-transfer transfer transfer channel-1 $PROVIDER_WALLET 1000$CONSUMER_DENOM --from $CONSUMER_WALLET --keyring-backend test -y -b sync --gas 500000 --fees 5000$CONSUMER_DENOM
echo "Waiting for the transfer to reach the provider chain..."
sleep 60
echo "$CHAIN_ID bank blances after sending: $PROVIDER_WALLET"
$CHAIN_BINARY --home $HOME_1 q bank balances $PROVIDER_WALLET
DENOM_AMOUNT=$($CHAIN_BINARY --home $HOME_1 q bank balances $PROVIDER_WALLET -o json | jq -r '.balances | length')
if [ $DENOM_AMOUNT -lt $EXPECTED_DENOMS ]; then
    echo "Found less than expected denoms in provider wallet."
    exit 1
fi
echo "Found the right amount of denoms in the provider wallet."

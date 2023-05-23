#!/bin/bash
# Test consensus key assignment

# Transfer provider token to consumer chain
echo "Setting the current key as the consumer chain consensus key..."
VAL2_KEY=$($CHAIN_BINARY tendermint show-validator --home $HOME_2)
$CHAIN_BINARY tx provider assign-consensus-key $CONSUMER_CHAIN_ID $VAL2_KEY --from $MONIKER_2 --gas auto --fees 1000$DENOM -b block -y --home $HOME_2
echo "Waiting for the key to be assigned on the consumer chain..."
sleep 30
PROVIDER_ADDRESS=$($CHAIN_BINARY tendermint show-address --home $HOME_2)
CONSUMER_ADDRESS=$($CHAIN_BINARY q provider validator-consumer-key $CONSUMER_CHAIN_ID $PROVIDER_ADDRESS --home $HOME_2 -o json | jq -r '.consumer_address')
if [ $PROVIDER_ADDRESS != $CONSUMER_ADDRESS ]; then
    echo "Provider address does not match consumer address."
    exit 1
fi
echo "Consumer address set to match the provider's."

#!/bin/bash
# Test Validator Set Changes

# Delegate additional stake to val 1
echo "Delegating additional stake to $MONIKER_1..."
$CHAIN_BINARY --home $HOME_1 tx staking delegate $VALOPER_1 $DELEGATE_2_AMOUNT$DENOM --from $MONIKER_2 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -b sync -y --chain-id $CHAIN_ID
# Wait for consumer chain to get validator set update
echo "Waiting for the validator set update to reach the consumer chain..."
sleep 60
PROVIDER_BADDRESS=$(jq -r '.address' $HOME_1/config/priv_validator_key.json)
PROVIDER_POWER=$(curl -s http://localhost:$VAL1_RPC_PORT/validators | jq -r '.result.validators[] | select(.address=="'$PROVIDER_BADDRESS'") | '.voting_power'')

# Verify new voting power in consumer chain
CONSUMER_POWER=$(curl -s http://localhost:$CON1_RPC_PORT/validators | jq -r '.result.validators[] | select(.address=="'$PROVIDER_BADDRESS'") | '.voting_power'')

echo "Top validator VP: $PROVIDER_POWER (provider), $CONSUMER_POWER (consumer)"
if [ $PROVIDER_POWER != $CONSUMER_POWER ]; then
    echo "Consumer chain validator set does not match the provider's."
    exit 1
fi
echo "Consumer chain validator set matches the provider's."

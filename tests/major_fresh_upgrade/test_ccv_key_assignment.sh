#!/bin/bash
# Test Validator Set Changes

PROVIDER_ADDRESS=$(jq -r '.address' $HOME_1/config/priv_validator_key.json)
CONSUMER_ADDRESS=$(jq -r '.address' $CONSUMER_HOME_1/config/priv_validator_key.json)

# Delegate additional stake to val 1
echo "Delegating additional stake to $MONIKER_1..."
command="$CHAIN_BINARY --home $HOME_1 tx staking delegate $VALOPER_1 $VAL_STAKE_STEP$DENOM --from $MONIKER_1 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y --chain-id $CHAIN_ID -o json"
TXHASH=$($command | jq -r '.txhash')
sleep $(($COMMIT_TIMEOUT+2))
$CHAIN_BINARY q tx $TXHASH --home $HOME_1
# Wait for consumer chain to get validator set update
echo "Waiting for the validator set update to reach the consumer chain..."
sleep $(($COMMIT_TIMEOUT*8))
# journalctl -u $PROVIDER_SERVICE_1 | tail -n 200
# journalctl -u $RELAYER | tail -n 200

PROVIDER_ADDRESS=$(jq -r '.address' $HOME_1/config/priv_validator_key.json)
PROVIDER_POWER=$(curl -s http://localhost:$VAL1_RPC_PORT/validators | jq -r '.result.validators[] | select(.address=="'$PROVIDER_ADDRESS'") | '.voting_power'')

# Verify new voting power in consumer chain
curl http://localhost:$CON1_RPC_PORT/validators
CONSUMER_POWER=$(curl -s http://localhost:$CON1_RPC_PORT/validators | jq -r '.result.validators[] | select(.address=="'$CONSUMER_ADDRESS'") | '.voting_power'')

if [ -z $PROVIDER_POWER ] || [ -z $CONSUMER_POWER ]; then
    echo "Not all validator powers are available!"
    exit 1
fi

echo "Top validator VP: $PROVIDER_POWER (provider), $CONSUMER_POWER (consumer)"
if [ $PROVIDER_POWER != $CONSUMER_POWER ]; then
    echo "Consumer chain validator set does not match the provider's."
    exit 1
fi
echo "Consumer chain validator set matches the provider's."

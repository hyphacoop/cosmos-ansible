#!/bin/bash

# Try creating a validator with a minimum commision of less than 5% before and after the upgrade
MCVAL_HOME_1=/home/runner/.mcval1
MCVAL_HOME_2=/home/runner/.mcval2
MCVAL_SERVICE_1=mcval1.service
MCVAL_SERVICE_2=mcval2.service

echo "TEST: proposal submission deposit must be at least 10% of the minimum deposit."
params=$($CHAIN_BINARY q gov params --home $HOME_1 -o json | jq -r '.')
echo $params

echo "Submitting proposal with < 10% of minimum deposit"

if $UPGRADED_V15 ; then
    $CHAIN_BINARY tx gov submit-proposal --title="Test Proposal" --description="Test Proposal" \
    --type="Text" \
    --from $WALLET_1 --home $HOME_1 \
    --gas $GAS --gas_adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM \
    --deposit="1000$DENOM" -Y
else
    $CHAIN_BINARY tx gov submit-proposal --title="Test Proposal" --description="Test Proposal" \
    --type="Text" \
    --from $WALLET_1 --home $HOME_1 \
    --gas $GAS --gas_adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM \
    --deposit="1000$DENOM" -Y
fi
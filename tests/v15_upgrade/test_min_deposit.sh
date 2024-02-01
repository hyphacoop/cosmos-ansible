#!/bin/bash

# Try creating a validator with a minimum commision of less than 5% before and after the upgrade
MCVAL_HOME_1=/home/runner/.mcval1
MCVAL_HOME_2=/home/runner/.mcval2
MCVAL_SERVICE_1=mcval1.service
MCVAL_SERVICE_2=mcval2.service

if $UPGRADED_V15 ; then
    echo "TEST: proposal submission deposit must be at least 10% of the minimum deposit."

    $CHAIN_BINARY tx gov submit-legacy-proposal --title="Test Proposal" --description="Test Proposal" \
    --type="Text" \
    --from $WALLET_1 --home $HOME_1 \
    --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM \
    --deposit="1000$DENOM" -y  >>prop_response.log 2>&1 
    cat prop_response.log
    fail_line=$(cat prop_response.log | grep "minimum deposit is too small")
    echo "$fail_line"
    if [[ -z "$fail_line" ]]; then
        echo "FAIL: Validator creation did not output error with insufficient deposit"
        exit 1
    else
        echo "PASS: Validator creation with insufficient outputs: $fail_line"
    fi

    $CHAIN_BINARY tx gov submit-legacy-proposal --title="Test Proposal" --description="Test Proposal" \
    --type="Text" \
    --from $WALLET_1 --home $HOME_1 \
    --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM \
    --deposit="1000000$DENOM" -y -o json
else

    echo "Setting minimum deposit to 10ATOM..."
    tests/param_change.sh tests/v15_upgrade/proposal-10atom-deposit.json
    params=$($CHAIN_BINARY q gov params --home $HOME_1 -o json | jq -r '.')
    echo $params

    echo "TEST: proposal submission deposit must be at least 10% of the minimum deposit."
    code=$($CHAIN_BINARY tx gov submit-proposal --title="Test Proposal" --description="Test Proposal" \
    --type="Text" \
    --from $WALLET_1 --home $HOME_1 \
    --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM \
    --deposit="1000$DENOM" -y -o json | jq -r '.code')
    if [[ "$code" == "3" ]]; then
       echo "PASS: code 3 was received."
    else
       echo "FAIL: code 3 was not received."
    fi

     code=$($CHAIN_BINARY tx gov submit-proposal --title="Test Proposal" --description="Test Proposal" \
    --type="Text" \
    --from $WALLET_1 --home $HOME_1 \
    --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM \
    --deposit="1000000$DENOM" -y -o json | jq -r '.code')
    if [[ "$code" == "0" ]]; then
       echo "PASS: code 0 was received."
    else
       echo "FAIL: code 0 was not received."
    fi
fi
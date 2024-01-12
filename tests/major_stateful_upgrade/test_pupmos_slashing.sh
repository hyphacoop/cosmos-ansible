#!/bin/bash

submit_proposal_cmd="gaiad --home $HOME_1 tx provider submit-consumer-double-voting tests/major_stateful_upgrade/double-signed-evidence.json tests/major_stateful_upgrade/double-signed-ibc-header.json --from $MONIKER_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICES$DENOM --chain-id $CHAIN_ID -y -b sync"

echo "Running: $submit_proposal_cmd"
$submit_proposal_cmd

exit_code=$?
echo "cmd exit code: $exit_code"

if [ $exit_code -eq 0 ]
then
    echo "ERROR: submit-consumer-double-voting submitted successfully..."
    submit_successful=1
fi

echo "Waiting for tx to be applied to block"
sleep 10

echo "Querying slashing result"
slashing_result=$(gaiad --home $HOME_1 q slashing signing-info '{"@type":"/cosmos.crypto.ed25519.PubKey","key":"0Nu7qOxlaLNKgOKM2Ck0fB6aKdsH1tjOeJw18VtES2g="}' -o json | jq -r '.tombstoned')

echo "PUPMOS slashing result: $slashing_result"

if [ "$slashing_result" != "false" ]
then
    echo "PUPMOS slashing result is not false"
    slashing_not_false=1
fi

if [ $submit_successful ] || [ $slashing_not_false ]
then
    echo "PUPMOS test failed!"
    exit 1
else
    echo "PUPMOS is safe!"
fi

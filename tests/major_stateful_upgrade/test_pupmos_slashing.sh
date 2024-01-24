#!/bin/bash

submit_proposal_cmd="gaiad --home $HOME_1 tx provider submit-consumer-double-voting tests/major_stateful_upgrade/double-signed-evidence.json tests/major_stateful_upgrade/double-signed-ibc-header.json --from $MONIKER_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICES$DENOM --chain-id $CHAIN_ID -y -b sync -o json"

echo "Running: $submit_proposal_cmd"
TXHASH=$($submit_proposal_cmd | jq '.txhash' | tr -d '"')

sleep 90
echo "Transection TX hash is: $TXHASH"
gaiad --home $HOME_1 q tx $TXHASH

exit 1 
while [ $try -lt 5 ]; do
    code=$($CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq '.code')
    echo "Code is: $code"
    if [ -z $code ]; then
        echo "code returned blank, tx was unsuccessful. Try: $try"
        let try=$try+1
        sleep 20
    elif [ $code -ne 0 ]; then
        echo "code returned not 0, tx was unsuccessful. Try: $try"
        let try=$try+1
        sleep 20
    else
        echo "tx was successful"
        break
    fi
done
if [ $try -gt 4 ]; then
    echo "maximum query reached tx unsuccessful."
    #$CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq '.'
    exit 1
fi

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

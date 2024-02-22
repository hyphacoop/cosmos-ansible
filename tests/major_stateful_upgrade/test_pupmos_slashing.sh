#!/bin/bash

submit_proposal_cmd="gaiad --home $HOME_1 tx provider submit-consumer-double-voting tests/major_stateful_upgrade/double-signed-evidence.json tests/major_stateful_upgrade/double-signed-ibc-header.json --from $MONIKER_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICES$DENOM --chain-id $CHAIN_ID -y -b sync -o json"

echo "Running: $submit_proposal_cmd"
TXHASH=$($submit_proposal_cmd | jq '.txhash' | tr -d '"')

echo "Transection TX hash is: $TXHASH"

# wait for 3 blocks
echo "Waiting for 3 blocks to be comitted"
tests/test_block_production.sh 127.0.0.1 $VAL1_RPC_PORT 3 10

echo "Query txhash:"
gaiad --home $HOME_1 q tx $TXHASH -o json --home $HOME_1 | jq '.'

code=$($CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq '.code')
echo "Code is: $code"
if [ -z $code ]; then
    echo "code returned blank, tx was unsuccessful."
    echo "PUPMOS is safe!"
elif [ $code -ne 0 ]; then
    echo "code returned not 0, tx was unsuccessful."
    echo "PUPMOS is safe!"
else
    echo "tx was successful"
    echo "PUPMOS slashing was commited to a block!"
    exit 1
fi

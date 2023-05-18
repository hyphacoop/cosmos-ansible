#!/bin/bash

EXPECTED_CHAIN_COUNT=1

# Check consumer chains list has one 
CHAIN_COUNT=$($CHAIN_BINARY q provider list-consumer-chains --home $HOME_1 -o json | jq -r '.chains | length' )
echo "Current chain count: $CHAIN_COUNT"
if [ "$CHAIN_COUNT" -ne "$EXPECTED_CHAIN_COUNT" ]; then
    echo "Too many consumer chains are still running."
    exit 1
fi

#!/bin/bash

# Test number of signatures
RPC_PORT=$1
VALIDATOR_COUNT=$2
curl -s http://localhost:$RPC_PORT/block | jq -r '.result.block.last_commit.signatures[]'
sigs_available=$(curl -s http://localhost:$RPC_PORT/block | jq -r '.result.block.last_commit.signatures[].signature == null | select(. == false)' | wc -l)
echo "$sigs_available signatures collected."
if [ $sigs_available -lt $VALIDATOR_COUNT ]; then
    echo "Not all validators are signing blocks."
    exit 1
fi
echo "All validators are signing blocks."

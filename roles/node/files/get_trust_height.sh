#!/bin/sh

# Retrieve trust height
# $1: rpc address
INTERVAL=1000
LATEST_HEIGHT=$(curl -s $1/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$(($LATEST_HEIGHT-$INTERVAL))
echo -n $BLOCK_HEIGHT

#!/bin/sh

# Retrieve trust height
# $1: rpc address
INTERVAL=1000
LATEST_HEIGHT=$(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:107.0) Gecko/20100101 Firefox/107.0" -s $1/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$(($LATEST_HEIGHT-$INTERVAL))
echo -n $BLOCK_HEIGHT

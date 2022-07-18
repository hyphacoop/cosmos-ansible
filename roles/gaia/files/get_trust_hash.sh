#!/bin/sh

# Retrieve hash ID
# $1: rpc address
# $2: block height
echo -n $(curl -s "$1/block?height=$2" | jq -r .result.block_id.hash)

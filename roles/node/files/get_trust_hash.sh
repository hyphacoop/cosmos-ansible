#!/bin/sh

# Retrieve hash ID
# $1: rpc address
# $2: block height
echo -n $(curl -A "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:107.0) Gecko/20100101 Firefox/107.0" -s "$1/block?height=$2" | jq -r .result.block_id.hash)

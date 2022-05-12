#!/bin/bash

gaia_host=$1

HEIGHT=$(curl -s $1/block | jq -r .result.block.header.height)
sleep 10
HEIGHT2=$(curl -s $1/block | jq -r .result.block.header.height)

echo "$HEIGHT"
echo "$HEIGHT2"
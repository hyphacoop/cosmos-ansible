#!/bin/bash 
set -x

gaia_host=$1

HEIGHT=$(curl -s http://$1/block | jq -r .result.block.header.height)
sleep 10
HEIGHT2=$(curl -s http://$1/block | jq -r .result.block.header.height)

echo "$HEIGHT"
echo "$HEIGHT2"
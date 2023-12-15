#!/bin/bash

host=$1
port=$2

still_syncing="true"
while [ $still_syncing == "true" ]
do
	still_syncing=$(curl -s ${host}:${port}/status | jq -r .result.sync_info.catching_up)
	echo "Still Syncing: $still_syncing"
	sleep 5
done
echo "Done syncing"

#!/bin/bash

still_syncing="true"
while [ $still_syncing == "true" ]
do
	still_syncing=$(curl -s 127.0.0.1:26657/status | jq -r .result.sync_info.still_syncing)
	echo "Still Syncing: $still_syncing"
	sleep 5
done
echo "Done syncing"

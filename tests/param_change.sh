#!/bin/bash

proposal_json=$1
if [ $COSMOS_SDK == "v45" ]; then
proposal="$CHAIN_BINARY tx gov submit-proposal param-change $proposal_json --from $WALLET_1 --home $HOME_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y"
elif [ $COSMOS_SDK == "v47" ]; then
proposal="$CHAIN_BINARY tx gov submit-legacy-proposal param-change $proposal_json --from $WALLET_1 --home $HOME_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y"
fi
echo $proposal
txhash=$($proposal | jq -r .txhash)
sleep $(( $COMMIT_TIMEOUT*2 ))
echo "Proposal hash: $txhash"
proposal_id=$($CHAIN_BINARY --output json q tx $txhash --home $HOME_1 | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')
vote="$CHAIN_BINARY tx gov vote $proposal_id yes --from $WALLET_1 --home $HOME_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json"
txhash=$($vote | jq -r .txhash)
sleep $(( $COMMIT_TIMEOUT*2 ))
echo "Vote hash: $txhash"
sleep $VOTING_PERIOD
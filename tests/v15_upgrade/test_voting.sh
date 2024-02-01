#!/bin/bash

# Try creating a validator with a minimum commision of less than 5% before and after the upgrade

if $UPGRADED_V15 ; then
   echo "TEST: Vote from an account with no delegations."
else
   $CHAIN_BINARY keys add voter1 --home $HOME_1
   voter1=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="voter1").address')
   $CHAIN_BINARY tx bank send $WALLET_1 $voter1 10000000$DENOM --home $HOME_1 --from $WALLET_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
   sleep $(( $COMMIT_TIMEOUT*2 ))

   output=$($CHAIN_BINARY tx gov submit-proposal --title="Test Proposal" --description="Test Proposal" \
    --type="Text" \
    --from $WALLET_1 --home $HOME_1 \
    --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM \
    --deposit="1000000$DENOM" -y -o json)
   code=$(echo $output | jq '.code')
    if [[ "$code" == "0" ]]; then
       echo "PASS: code 0 was received."
    else
       echo "FAIL: code 0 was not received."
       exit 1
    fi
    sleep $(($COMMIT_TIMEOUT+2))

   echo "TEST: Vote from an account with no delegations."
   txhash=$(echo $output | jq '.txhash')
   
   $CHAIN_BINARY q tx $txhash --home $HOME_1 -o json | jq '.'

fi
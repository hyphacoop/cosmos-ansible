#!/bin/bash

# Try creating a validator with a minimum commision of less than 5% before and after the upgrade

if $UPGRADED_V15 ; then

   voter1=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="voter1").address')
   
   output=$($CHAIN_BINARY tx gov submit-legacy-proposal --title="Test Proposal" --description="Test Proposal" \
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
   txhash=$(echo $output | jq -r '.txhash')
   proposal_id=$($CHAIN_BINARY --output json q tx $txhash --home $HOME_1 | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')
   echo "Proposal ID: $proposal_id"
   echo "TEST: Vote from an account with no delegations."
   $CHAIN_BINARY q staking delegations $voter1 --home $HOME_1
   txhash=$($CHAIN_BINARY tx gov vote $proposal_id yes --from $voter1 --home $HOME_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json | jq -r '.txhash')
   sleep $(($COMMIT_TIMEOUT+2))
   $CHAIN_BINARY version
   tx_query=$($CHAIN_BINARY q tx $txhash --home $HOME_1)
   echo "Vote tx query:"
   echo "$tx_query"
   code=$($CHAIN_BINARY q tx $txhash --home $HOME_1 -o json | jq -r '.code')
   echo "Vote tx code: \"$code\""
   if [[ "$code" == "0" ]]; then
      echo "FAIL: code 0 was received."
      exit 1
   else
      echo "PASS: code 0 was not received."
   fi
   sleep $VOTING_PERIOD
   $CHAIN_BINARY q gov proposal $proposal_id --home $HOME_1 -o json | jq '.'
   
   $CHAIN_BINARY tx staking delegate $VALOPER_1 1$DENOM --from $voter1 --home $HOME_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
   sleep $(( $COMMIT_TIMEOUT*2 ))
   output=$($CHAIN_BINARY tx gov submit-legacy-proposal --title="Test Proposal" --description="Test Proposal" \
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
   txhash=$(echo $output | jq -r '.txhash')
   proposal_id=$($CHAIN_BINARY --output json q tx $txhash --home $HOME_1 | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')
   echo "Proposal ID: $proposal_id"
   echo "TEST: Vote from an account with 1uatom in delegations."
   $CHAIN_BINARY q staking delegations $voter1 --home $HOME_1
   txhash=$($CHAIN_BINARY tx gov vote $proposal_id yes --from $voter1 --home $HOME_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json | jq -r '.txhash')
   sleep $(($COMMIT_TIMEOUT+2))
   tx_query=$($CHAIN_BINARY q tx $txhash --home $HOME_1)
   echo "Vote tx query:"
   echo "$tx_query"
   code=$($CHAIN_BINARY q tx $txhash --home $HOME_1 -o json | jq -r '.code')
   echo "Vote tx code: \"$code\""
   if [[ "$code" == "0" ]]; then
      echo "FAIL: code 0 was received."
      exit 1
   else
      echo "PASS: code 0 was not received."
   fi
   sleep $VOTING_PERIOD
   $CHAIN_BINARY q gov proposal $proposal_id --home $HOME_1 -o json | jq '.'

   $CHAIN_BINARY tx staking delegate $VALOPER_1 1000000$DENOM --from $voter1 --home $HOME_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
   sleep $(( $COMMIT_TIMEOUT*2 ))
   output=$($CHAIN_BINARY tx gov submit-legacy-proposal --title="Test Proposal" --description="Test Proposal" \
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
   txhash=$(echo $output | jq -r '.txhash')
   proposal_id=$($CHAIN_BINARY --output json q tx $txhash --home $HOME_1 | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')
   echo "Proposal ID: $proposal_id"
   echo "TEST: Vote from an account with 1_000_001uatom in delegations."
   $CHAIN_BINARY q staking delegations $voter1 --home $HOME_1
   txhash=$($CHAIN_BINARY tx gov vote $proposal_id yes --from $voter1 --home $HOME_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json | jq -r '.txhash')
   sleep $(($COMMIT_TIMEOUT+2))
   tx_query=$($CHAIN_BINARY q tx $txhash --home $HOME_1)
   echo "Vote tx query:"
   echo "$tx_query"
   code=$($CHAIN_BINARY q tx $txhash --home $HOME_1 -o json | jq -r '.code')
   echo "Vote tx code: \"$code\""
   if [[ "$code" == "0" ]]; then
      echo "PASS: code 0 was received."
   else
      echo "FAIL: code 0 was not received."
      exit 1
   fi
   sleep $VOTING_PERIOD
   $CHAIN_BINARY q gov proposal $proposal_id --home $HOME_1 -o json | jq '.'

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

   txhash=$(echo $output | jq -r '.txhash')
   proposal_id=$($CHAIN_BINARY --output json q tx $txhash --home $HOME_1 | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')
   echo "Proposal ID: $proposal_id"

   echo "TEST: Vote from an account with no delegations."
   txhash=$($CHAIN_BINARY tx gov vote $proposal_id yes --from $voter1 --home $HOME_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json | jq -r '.txhash')
   sleep $(($COMMIT_TIMEOUT+2))
   $CHAIN_BINARY q tx $txhash --home $HOME_1 -o json | jq '.'
   sleep $VOTING_PERIOD
   $CHAIN_BINARY q gov proposal $proposal_id --home $HOME_1 -o json | jq '.'


fi
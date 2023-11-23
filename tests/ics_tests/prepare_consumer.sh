#!/bin/bash
# Prepare a consumer chain to be started

if $PROVIDER_V3 ; then
    echo "Patching add template with spawn time..."
    spawn_time=$(date -u --iso-8601=ns | sed s/+00:00/Z/ | sed s/,/./)
    jq -r --arg SPAWNTIME "$spawn_time" '.spawn_time |= $SPAWNTIME' tests/ics_tests/legacy-proposal-add-template.json > proposal-add-spawn.json
    sed "s%\"chain_id\": \"\"%\"chain_id\": \"$CONSUMER_CHAIN_ID\"%g" proposal-add-spawn.json > proposal-add-$CONSUMER_CHAIN_ID.json
    rm proposal-add-spawn.json
    echo "Submitting proposal..."
    proposal="$CHAIN_BINARY tx gov submit-legacy-proposal consumer-addition proposal-add-$CONSUMER_CHAIN_ID.json --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --from $WALLET_2 --keyring-backend test --home $HOME_1 --chain-id $CHAIN_ID -y -o json"    
else
    echo "Patching add template with spawn time..."
    spawn_time=$(date -u --iso-8601=ns | sed s/+00:00/Z/ | sed s/,/./)
    jq -r --arg SPAWNTIME "$spawn_time" '.spawn_time |= $SPAWNTIME' tests/patch_upgrade/proposal-add-template.json > proposal-add-spawn.json
    sed "s%\"chain_id\": \"\"%\"chain_id\": \"$CONSUMER_CHAIN_ID\"%g" proposal-add-spawn.json > proposal-add-$CONSUMER_CHAIN_ID.json
    rm proposal-add-spawn.json
    echo "Submitting proposal..."
    proposal="$CHAIN_BINARY tx gov submit-proposal consumer-addition proposal-add-$CONSUMER_CHAIN_ID.json --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --from $WALLET_2 --keyring-backend test --home $HOME_1 --chain-id $CHAIN_ID -b block -y -o json"
fi

echo $proposal
txhash=$($proposal | jq -r .txhash)
# Wait for the proposal to go on chain
sleep $(($COMMIT_TIMEOUT*2))

# Get proposal ID from txhash
echo "Getting proposal ID from txhash..."
$CHAIN_BINARY q tx $txhash --home $HOME_1
proposal_id=$($CHAIN_BINARY q tx $txhash --home $HOME_1 --output json | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')

$CHAIN_BINARY q gov proposals --home $HOME_1

echo "Voting on proposal $proposal_id..."
$CHAIN_BINARY tx gov vote $proposal_id yes --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --from $WALLET_1 --keyring-backend test --home $HOME_1 --chain-id $CHAIN_ID -y
sleep $(($COMMIT_TIMEOUT+2))
$CHAIN_BINARY q gov tally $proposal_id --home $HOME_1

echo "Waiting for proposal to pass..."
sleep $(($COMMIT_TIMEOUT*3))
$CHAIN_BINARY q gov proposals --home $HOME_1

echo "Collecting the CCV state..."
$CHAIN_BINARY q provider consumer-genesis $CONSUMER_CHAIN_ID -o json --home $HOME_1
$CHAIN_BINARY q provider consumer-genesis $CONSUMER_CHAIN_ID -o json --home $HOME_1 > ccv-pre.json
jq '.params |= . + {"soft_opt_out_threshold": "0.10"}' ccv-pre.json > ccv-optout.json


echo "Patching the CCV state with the provider reward denom"
jq --arg DENOM "$CONSUMER_DENOM" '.params.reward_denoms = [$DENOM]' ccv-optout.json > ccv-reward.json
cp ccv-reward.json ccv.json

jq '.' ccv.json

if $CONSUMER_V120 ; then
    echo "Patching for ICS v1.2.0"
    jq 'del(.preCCV)' ccv.json > ccv-120.json

    # For provider >= v3.0.0
    jq 'del(.provider_client_state.proof_specs[0].prehash_key_before_comparison)' ccv-120.json > ccv-120-1.json    
    jq 'del(.provider_client_state.proof_specs[1].prehash_key_before_comparison)' ccv-120-1.json > ccv-120-2.json    
    cp ccv-120-2.json ccv.json
fi

if $CONSUMER_V200 ; then
    # For provider >= v3.0.0
    jq 'del(.provider_client_state.proof_specs[0].prehash_key_before_comparison)' ccv.json > ccv-200-1.json    
    jq 'del(.provider_client_state.proof_specs[1].prehash_key_before_comparison)' ccv-200-1.json > ccv-200-2.json    
    cp ccv-200-2.json ccv.json
fi

echo "Patching the consumer genesis file..."
jq -s '.[0].app_state.ccvconsumer = .[1] | .[0]' $CONSUMER_HOME_1/config/genesis.json ccv.json > consumer-genesis.json
cp consumer-genesis.json $CONSUMER_HOME_1/config/genesis.json
cp consumer-genesis.json $CONSUMER_HOME_2/config/genesis.json
cp consumer-genesis.json $CONSUMER_HOME_3/config/genesis.json
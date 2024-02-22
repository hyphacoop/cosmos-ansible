#!/bin/bash

# Change UnbondingTime
echo "Set UnbondingTime time..."
proposal="$CHAIN_BINARY tx gov submit-proposal tests/major_stateful_upgrade/unbonding-prop.json --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --from $WALLET_1 --keyring-backend test --home $HOME_1 --chain-id $CHAIN_ID -b sync -y -o json"
echo $proposal
gaiadout=$($proposal)
echo "gaiad output:"
echo "$gaiadout"
echo "$gaiadout" > ~/artifact/$CHAIN_ID-tx-UnbondingTime.txt

txhash=$(echo "$gaiadout" | jq -r .txhash)
# Wait for the proposal to go on chain
sleep 6

# Get proposal ID from txhash
echo "Getting proposal ID from txhash..."
$CHAIN_BINARY q tx $txhash --home $HOME_1
proposal_id=$($CHAIN_BINARY q tx $txhash --home $HOME_1 --output json | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')

echo "Voting on proposal $proposal_id..."
$CHAIN_BINARY tx gov vote $proposal_id yes --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --from $WALLET_1 --keyring-backend test --home $HOME_1 --chain-id $CHAIN_ID -b sync -y
$CHAIN_BINARY q gov tally $proposal_id --home $HOME_1
echo "Waiting for proposal to pass..."
sleep $VOTING_PERIOD

$CHAIN_BINARY q gov proposal $proposal_id --home $HOME_1
echo "$CHAIN_BINARY q params subspace staking UnbondingTime --home $HOME_1"
$CHAIN_BINARY q params subspace staking UnbondingTime --home $HOME_1
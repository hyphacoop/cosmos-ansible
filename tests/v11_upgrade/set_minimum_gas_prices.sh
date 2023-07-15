#!/bin/bash
# Set minimum gas prices to 0.001uatom

set +e

echo "Submitting proposal to update the minimum gas prices..."
proposal="$CHAIN_BINARY tx gov submit-proposal param-change tests/v11_upgrade/min_gas_prices_proposal.json --from $WALLET_1 --gas auto --fees $BASE_FEES$DENOM -b block -y -o json --home $HOME_1 --gas-adjustment 1.2"
echo $proposal
txhash=$($proposal | jq -r .txhash)
# Wait for the proposal to go on chain
sleep 6

# Get proposal ID from txhash
echo "Get proposal ID from txhash"
proposal_id=$($CHAIN_BINARY --output json q tx $txhash --home $HOME_1 | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')

# Vote yes on the proposal
echo "Submitting the \"yes\" vote to proposal $proposal_id"
vote="$CHAIN_BINARY tx gov vote $proposal_id yes --from $WALLET_1 --gas auto --fees $BASE_FEES$DENOM -b block --yes --home $HOME_1"
echo $vote
$vote
sleep 6

# Wait for the voting period to be over
echo "Waiting for the voting period to end..."
sleep 6

# Query the globalfee params
$CHAIN_BINARY q globalfee minimum-gas-prices -o json --home $HOME_1 > globalfee-pre-upgrade.json
jq '.' globalfee-pre-upgrade.json
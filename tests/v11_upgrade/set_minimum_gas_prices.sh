#!/bin/bash
# Set minimum gas prices to 0.001uatom
validator_address=$(jq -r '.address' ~/.gaia/validator.json)

echo "Submitting proposal to update the minimum gas prices..."
proposal="gaiad tx gov submit-proposal param-change tests/v11_upgrade/min_gas_prices_proposal.json --from $validator_address --gas auto --fees 500uatom -b block -y -o json"
echo $proposal
txhash=$($proposal | jq -r .txhash)
# Wait for the proposal to go on chain
sleep 6

# Get proposal ID from txhash
echo "Get proposal ID from txhash"
proposal_id=$(gaiad --output json q tx $txhash | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')

# Vote yes on the proposal
echo "Submitting the \"yes\" vote to proposal $proposal_id"
vote="gaiad tx gov vote $proposal_id yes --from $validator_address --fees 500uatom --yes"
echo $vote
$vote
sleep 6

# Wait for the voting period to be over
echo "Waiting for the voting period to end..."
sleep 6

# Query the globalfee params
gaiad q globalfee minimum-gas-prices -o json > globalfee-pre-upgrade.json
jq '.' globalfee-pre-upgrade.json
#!/bin/bash 
# Test a gaia software upgrade via governance proposal.
# It assumes gaia is running on the local host.

gaia_host=$1
gaia_port=$2
upgrade_name=$3

echo "Attempting upgrade to $upgrade_name."

# Auto set denom
echo "Get denom from ~/.gaia/config/genesis.json"
denom=$(jq -r '.app_state.gov.deposit_params.min_deposit[].denom' ~/.gaia/config/genesis.json)

# Get the current gaia version from the API
echo "Get the current gaia version from the API"
chain_version=$(curl -s http://$gaia_host:$gaia_port/abci_info | jq -r .result.response.version)

# Get chain-id from the API
echo "Get chain-id from the API"
chain_id=$(curl -s http://$gaia_host:$gaia_port/status | jq -r .result.node_info.network)

echo "Upgrading to $upgrade_name."

# Set time to wait for proposal to pass
echo "Get voting_period from genesis file"
voting_period=$(jq -r '.app_state.gov.voting_params.voting_period' ~/.gaia/config/genesis.json)
voting_period_seconds=${voting_period::-1}
echo "Using ($voting_period_seconds)s voting period to calculate the upgrade height."
    
# Calculate upgrade height
echo "Calculate upgrade height"
let voting_blocks_delta=$voting_period_seconds/5+3
height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r .result.block.header.height)
upgrade_height=$(($height+$voting_blocks_delta))
echo "Upgrade block height set to $upgrade_height."

# Get validator address
echo "Querying gaiad for the validator address..."
validator_address=$(jq -r '.address' ~/.gaia/validator.json)
echo "The validator has address $validator_address."

# Auto download: Set the binary paths need for the proposal message
upgrade_info="{\"binaries\":{\"linux/amd64\":\"$DOWNLOAD_URL\"}}"
proposal="gaiad --output json tx gov submit-proposal software-upgrade $upgrade_name --from $validator_address --keyring-backend test --upgrade-height $upgrade_height --upgrade-info $upgrade_info --title gaia-upgrade --description 'test' --chain-id $chain_id --deposit 10$denom --fees 1000$denom --yes"

# Submit the proposal
echo "Submitting the upgrade proposal."
echo $proposal
txhash=$($proposal | jq -r .txhash)

# Wait for the proposal to go on chain
sleep 8

# Get proposal ID from txhash
echo "Get proposal ID from txhash"
proposal_id=$(gaiad --output json q tx $txhash | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')

# Vote yes on the proposal
echo "Submitting the \"yes\" vote to proposal $proposal_id"
vote="gaiad tx gov vote $proposal_id yes --from $validator_address --keyring-backend test --chain-id $chain_id --fees 1000$denom --yes"
echo $vote
$vote

# Wait for the voting period to be over
echo "Waiting for the voting period to end..."
sleep 8

echo "Upgrade proposal $proposal_id status:"
gaiad q gov proposal $proposal_id --output json | jq '.status'

# Wait until the right height is reached
echo "Waiting for the upgrade to take place at block height $upgrade_height..."
current_height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r '.result.block.header.height')
blocks_delta=$(($upgrade_height-$current_height))
tests/test_block_production.sh $gaia_host $gaia_port $blocks_delta
echo "The upgrade height was reached."

# Test gaia response
tests/test_gaia_response.sh $gaia_host $gaia_port

# Get running version
gaiad_upgraded_version=$(curl -s http://$gaia_host:$gaia_port/abci_info | jq -r .result.response.version)
echo "Current gaiad version: $gaiad_upgraded_version"

# Test block production
tests/test_block_production.sh $gaia_host $gaia_port

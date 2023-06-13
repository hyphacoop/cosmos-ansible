#!/bin/bash 
# Test a gaia software upgrade via governance proposal.
# It assumes gaia is running on the local host.

gaia_host=$1
gaia_port=$2
upgrade_name=$3

echo "Attempting upgrade to $upgrade_name."

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

# Auto download: Set the binary paths need for the proposal message
upgrade_info="{\"binaries\":{\"linux/amd64\":\"$DOWNLOAD_URL\"}}"
proposal="$CHAIN_BINARY --output json tx gov submit-proposal software-upgrade $upgrade_name --from $WALLET_1 --keyring-backend test --upgrade-height $upgrade_height --upgrade-info $upgrade_info --title gaia-upgrade --description 'test' --chain-id $CHAIN_ID --deposit $VAL_STAKE_STEP$DENOM --fees $BASE_FEES$DENOM --yes --home $HOME_1"

# Submit the proposal
echo "Submitting the upgrade proposal."
echo $proposal
txhash=$($proposal | jq -r .txhash)

# Wait for the proposal to go on chain
sleep 6

# Get proposal ID from txhash
echo "Get proposal ID from txhash"
proposal_id=$($CHAIN_BINARY --output json q tx $txhash --home $HOME_1 | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')

# Vote yes on the proposal
echo "Submitting the \"yes\" vote to proposal $proposal_id"
vote="$CHAIN_BINARY tx gov vote $proposal_id yes --from $WALLET_1 --keyring-backend test --chain-id $CHAIN_ID --fees $BASE_FEES$DENOM --yes --home $HOME_1"
echo $vote
$vote

# Wait for the voting period to be over
echo "Waiting for the voting period to end..."
sleep 6

echo "Upgrade proposal $proposal_id status:"
gaiad $CHAIN_BINARY gov proposal $proposal_id --output json --home $HOME_1 | jq '.status'

# Wait until the right height is reached
echo "Waiting for the upgrade to take place at block height $upgrade_height..."
current_height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r '.result.block.header.height')
blocks_delta=$(($upgrade_height-$current_height))
tests/test_block_production.sh $gaia_host $gaia_port $blocks_delta
echo "The upgrade height was reached."


# # Test gaia response
# tests/test_gaia_response.sh $gaia_host $gaia_port

# # Get running version
# gaiad_upgraded_version=$(curl -s http://$gaia_host:$gaia_port/abci_info | jq -r .result.response.version)
# echo "Current gaiad version: $gaiad_upgraded_version"

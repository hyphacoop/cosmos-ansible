#!/bin/bash 
# Test a gaia software upgrade via governance proposal.
# It assumes gaia is running on the local host.

gaia_host=$1
gaia_port=$2
upgrade_version=$3

echo "Attempting upgrade to $upgrade_version."

# Add gaiad to PATH
echo "Adding gaiad to PATH..."
export PATH="$PATH:~/.gaia/cosmovisor/current/bin"
echo "PATH=$PATH"

# Get the current gaia version from the API
gaiad_version=$(curl -s http://$gaia_host:$gaia_port/abci_info | jq -r .result.response.version)

# Submit upgrade proposal
gaiad_version_major=${gaiad_version:1:1}
echo "Current major version: $gaiad_version_major"

upgrade_version_major=${upgrade_version:1:1}
echo "Upgrade major version: $upgrade_version_major"
major_difference=$[ $upgrade_version_major-$gaiad_version_major ]

if [ $major_difference -eq 1 ]; then
    if [ $upgrade_version_major -eq 7 ]; then
        upgrade_name="v7-Theta"
    elif [ $upgrade_version_major -eq 8 ]; then
        upgrade_name="v8-Rho"
    fi
fi

if [ -n "$upgrade_name" ]; then
    echo "Upgrading to $upgrade_name."

    # Set time to wait for proposal to pass
    voting_period=$(curl -s http://localhost:26657/genesis\? | jq -r '.result.genesis.app_state.gov.voting_params.voting_period')
    # voting_period=${voting_period::-1}
    echo "Adding 5s to the voting period ($voting_period) to calculate the upgrade height."
    voting_period_seconds=${voting_period::-1}
    let voting_waiting_time=$voting_period_seconds+5

    # Calculate upgrade height
    let voting_blocks_delta=$voting_period_seconds/5+3
    height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r .result.block.header.height)
    upgrade_height=$(($height+$voting_blocks_delta))
    echo "Upgrade block height set to $upgrade_height."

    # Get validator address and account sequence
    # Sequence number must be added 1 for the vote to be accepted.
    echo "Querying gaiad for the validator address and account sequence..."
    validator_address=$(gaiad keys list --keyring-backend test --output json | jq -r '.[0].address')
    validator_sequence=$[ $(gaiad query auth account $validator_address --output json | jq -r '.sequence')+1 ]
    echo "The validator has address $validator_address, setting sequence # to $validator_sequence."

    # Auto download: Set the binary paths need for the proposal message
    download_path="https://github.com/cosmos/gaia/releases/download/$upgrade_version"
    upgrade_info="{\"binaries\":{\"linux/amd64\":\"$download_path/gaiad-$upgrade_version-linux-amd64\",\"linux/arm64\":\"$download_path/$upgrade_version/gaiad-$upgrade_version-linux-arm64\",\"darwin/amd64\":\"$download_path/gaiad-$upgrade_version-darwin-amd64\",\"windows/amd64\":\"$download_path/gaiad-$upgrade_version-windows-amd64.exe\"}}"
    proposal="gaiad tx gov submit-proposal software-upgrade $upgrade_name --from $validator_address --keyring-backend test --upgrade-height $upgrade_height --upgrade-info $upgrade_info --title gaia-upgrade --description 'test' --chain-id my-testnet --deposit 10stake --yes"

    # Submit the proposal and vote yes for it
    echo "Submitting the upgrade proposal."
    echo $proposal
    $proposal

    echo "Submitting the \"yes\" vote."
    vote="gaiad tx gov vote 1 yes --from $validator_address --keyring-backend test --chain-id my-testnet --sequence $validator_sequence --yes"
    echo $vote
    $vote

    # Wait for the voting period to be over
    echo "Waiting for the voting period to end..."
    sleep $voting_waiting_time

    echo "Upgrade proposal status:"
    gaiad q gov proposal 1 --output json | jq '.status'

    # Wait until the right height is reached
    height=0
    max_tests=60
    test_counter=0
    echo "Waiting for the upgrade to take place at block height $upgrade_height..."
    until [ $height -ge $upgrade_height ]
    do
        sleep 5
        if [ ${test_counter} -gt ${max_tests} ]
            then
            echo "Testing gaia for $test_counter times but did not reach height $upgrade_height"
            exit 2
        fi
        height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r .result.block.header.height)
        if [ -z "$height" ]
        then
            height=0
        fi
        echo "Block height: $height"
        test_counter=$(($test_counter+1))

    done
    echo "The upgrade height was reached."

    # Waiting until gaiad responds
    attempt_counter=0
    max_attempts=60
    echo "Waiting for gaia to come back online..."
    until $(curl --output /dev/null --silent --head --fail http://$gaia_host:$gaia_port)
    do
        if [ ${attempt_counter} -gt ${max_attempts} ]
        then
            echo ""
            echo "Tried connecting to gaiad for $attempt_counter times. Exiting."
            exit 3
        fi

        printf '.'
        attempt_counter=$(($attempt_counter+1))
        sleep 1
    done

    # Get running version
    gaiad_upgraded_version=$(curl -s http://$gaia_host:$gaia_port/abci_info | jq -r .result.response.version)
    echo "Current gaiad version: $gaiad_upgraded_version"

    # Check upgraded version is the one we want
    if [[ "$gaiad_upgraded_version" != "$upgrade_version" ]]; then
        echo "Requested $upgrade_version, but detected $gaiad_upgraded_version."
        exit 4
    fi

    # Check if gaiad is producing blocks
    test_counter=0
    max_tests=60
    cur_height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r .result.block.header.height)
    let stop_height=cur_height+10
    echo "Block height: $cur_height"
    echo "Waiting to reach block height $stop_height..."
    height=0
    until [ $height -ge $stop_height ]
    do
        sleep 5
        if [ ${test_counter} -gt ${max_tests} ]
        then
            echo "Testing gaia for $test_counter times but did not reached height $stop_height"
            exit 5
        fi
        height=$(curl -s http://$gaia_host:$gaia_port/block | jq -r .result.block.header.height)
        if [ -z "$height" ]
        then
            height=0
        fi
        echo "Block height: $height"
        test_counter=$(($test_counter+1))
    done
    echo "Upgraded gaiad is building blocks."

else
    echo "No upgrade name specified, skipping upgrade."
fi


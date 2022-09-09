#!/bin/bash
# Gaiad versions to start upgrade
start_version="v6.0.4"

# Gaiad Upgrade Test Function
gaiad_upgrade () {
    # do not exit on error
    set +e
    
    f_gaia_version=$1
    f_upgrade_version=$2
    f_latest_genesis=$3
    f_initial_height=$4
    sed -e '/genesis_url:/d' examples/inventory-local-genesis.yml > inventory.yml
    ansible-galaxy install -r requirements.yml
    ansible-playbook node.yml -i inventory.yml --extra-vars "target=local reboot=false minimum_gas_prices=0.0025uatom chain_version=$f_gaia_version chain_gov_testing=true priv_validator_key_file=examples/validator-keys/validator-40/priv_validator_key.json node_key_file=examples/validator-keys/validator-40/node_key.json genesis_file=$f_latest_genesis"
    
    # Restore the validator key and store /home/gaia/.gaia/validator.json
    su gaia -c "echo \"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art\" | ~/.gaia/cosmovisor/current/bin/gaiad --output json keys add val --keyring-backend test --recover 2> ~/.gaia/validator.json" # Use stderr until gaiad use stdout
    
    # Test to see if gaia is building blocks
    echo "Testing block productions on version: $f_gaia_version"
    su gaia -c "tests/test_block_production.sh 127.0.0.1 26657 $(($f_initial_height+10))"
    if [ $? -ne 0 ]
    then
        echo "Failed to build blocks on version: $f_gaia_version"
        f_pass=0
    else
        echo "Test building blocks for version: $f_gaia_version"
        f_pass=1
    fi

    # Test upgrading
    if [ $f_pass -eq 1 ]
    then
        echo "Testing upgrade"
        su gaia -c "tests/test_software_upgrade.sh 127.0.0.1 26657 $f_upgrade_version"
        if [ $? -ne 0 ]
        then
            f_message="Upgrade failed from $f_gaia_version to $f_upgrade_version"
            f_pass=0
        else
            f_message="Upgrade Successful from $f_gaia_version to $f_upgrade_version"
            f_pass=1
        fi
    else
        echo "SKIPPING testing upgrade due to failed job"
    fi

    # Happy path - transaction testing after upgrade
    echo "Testing happy path on version: $f_upgrade_version"
    if [ $f_pass -eq 1 ]
    then
        cp tests/test_tx_stateful.sh ~gaia/
        su gaia -c "cd ~ && ./test_tx_stateful.sh"
        if [ $? -ne 0 ]
        then
            echo "Happy path transaction test failed on version $f_upgrade_version"
            f_message="Happy path transaction test failed on version $f_upgrade_version"
            f_pass=0
        else
            echo "Happy path transaction test passed"
            f_message="Upgrade Successful from $f_gaia_version to $f_upgrade_version"
            f_pass=1
        fi
    else
        echo "SKIPPING happy path after upgrading gaia due to failed job"
    fi

    # Delete keys from keyring
    su gaia -c " ~/.gaia/cosmovisor/current/bin/gaiad keys delete --keyring-backend test val --yes"
    su gaia -c " ~/.gaia/cosmovisor/current/bin/gaiad keys delete --keyring-backend test test-account --yes"

    # Output messages to log
    if [ ! -d logs ]
    then
        mkdir logs
    fi
    echo "$(date +"%b %d %Y %H:%M:%S"): $f_message"
    echo "$(date +"%b %d %Y %H:%M:%S"): $f_message" > logs/tinkered-genesis-upgrade_"${f_gaia_version}"_"${f_upgrade_version}".log
    set -e
}

# Test upgrade using exported genesis
echo "Test upgrades using export genesis"
cd ~
pip3 install ansible
git clone git@github.com:hyphacoop/cosmos-ansible.git
cd cosmos-ansible/
# checkout running branch
git checkout "$gh_ansible_branch"

echo "transport = local" >> ansible.cfg
python3 tests/generate_version_matrix.py $start_version
upgrade=$(python3 tests/generate_upgrade_matrix.py $start_version)

# Loop through upgrade versions
i=0
jq -r .include[].gaia_version <<< "$upgrade" | while read -r gaia_start_version
do
    gaia_upgrade_version=$(jq -r ".include[$i].upgrade_version" <<< "$upgrade")
    echo "Run test on $gaia_start_version to $gaia_upgrade_version"
    gaiad_upgrade "$gaia_start_version" "$gaia_upgrade_version" ~/cosmos-genesis-tinkerer/mainnet-genesis-tinkered/tinkered-genesis_"${current_block_time}"_"${chain_version}"_"${current_block}".json.gz "$current_block"
    let i=$i+1
done

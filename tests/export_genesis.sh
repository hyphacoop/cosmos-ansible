#!/bin/bash
set -e

# cosmos next upgrade version name
cosmos_upgrade_name="v15"

# cosmos current major version name
export cosmos_current_name="v14"

# cosmos-genesis-tinkerer repo config
gh_branch="main"
gh_user="hypha-bot"

# get cosmos-ansible from $1
gh_ansible_branch=$1

# Store current date and time
start_date=$(date +"%Y%m%d_%H-%M-%S")

# Stop cosmovisor
echo "Stopping cosmovisor"
systemctl stop cosmovisor

# Use quicksync as statesync is not reliable
echo "Installing utils needed to quicksync and git"
apt-get install wget liblz4-tool aria2 bc -y

# Configure Git
echo "Configuring git"
cd ~
if [ ! -d ~/.ssh ]
then
    mkdir -m 700 ~/.ssh
fi
ssh-keyscan github.com >> ~/.ssh/known_hosts
ssh-keyscan files.polypore.xyz >> ~/.ssh/known_hosts
git config --global credential.helper store
git config --global user.name "$gh_user"
git config --global user.email $gh_user@users.noreply.github.com

echo "Creating script for gaia user"
echo "#!/bin/bash
echo \"cd ~/.gaia\"
cd ~/.gaia
# echo \"Set URL\"
# URL=\$(curl -sL https://quicksync.io/cosmos.json|jq -r '.[] |select(.file==\"cosmoshub-4-pruned\")|.url')
# echo \"URL set to: \$URL\"
# echo \"Starting download\"
# aria2c -x5 \$URL
# echo \"Execting \$(basename \$URL)\"
# lz4 -d \$(basename \$URL) | tar xf -
# echo \"Removing \$(basename \$URL)\"
# rm \$(basename \$URL)
if [ ! -L cosmovisor/current ]
then
    mkdir -p /home/gaia/.gaia/cosmovisor/upgrades/\$cosmos_current_name/bin
    cp /home/gaia/.gaia/cosmovisor/genesis/bin/gaiad  /home/gaia/.gaia/cosmovisor/upgrades/\$cosmos_current_name/bin/gaiad
    ln -s /home/gaia/.gaia/cosmovisor/upgrades/\$cosmos_current_name /home/gaia/.gaia/cosmovisor/current
fi
echo \"Syncing with gaiad version: \$(~gaia/.gaia/cosmovisor/current/bin/gaiad version)\"
" > ~gaia/quicksync.sh
chmod +x ~gaia/quicksync.sh
echo "Running ~gaia/quicksync.sh as gaia user"
su gaia -c '~gaia/quicksync.sh'

echo "Starting cosmovisor"
systemctl start cosmovisor

# Wait for gaia service to respond
echo "Waiting for gaia to respond"
attempt_counter=0
max_attempts=100
until $(curl --output /dev/null --silent --head --fail http://127.0.0.1:26657)
do
    if [ ${attempt_counter} -gt ${max_attempts} ]
    then
        echo ""
        echo "Tried connecting to gaiad for $attempt_counter times. Exiting."
        exit 1
    fi

    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 1
done

# Wait until gaiad is done catching up
catching_up="true"
while [ $catching_up == "true" ]
do
	catching_up=$(curl -s 127.0.0.1:26657/status | jq -r .result.sync_info.catching_up)
	echo "catching up: $catching_up"
	sleep 5
done
echo "Done catching up"

# Get current block height
current_block=$(curl -s 127.0.0.1:26657/block | jq -r .result.block.header.height)
echo "Current block: $current_block"

# Get block timestamp
current_block_time=$(curl -s 127.0.0.1:26657/block\?height="$current_block" | jq -r .result.block.header.time)
echo "Current block timestamp: $current_block_time"

# Stop cosmovisor before exporting
echo "stop and disable cosmovisor"
systemctl disable --now cosmovisor

# Clone cosmos-genesis-tinkerer
echo "Cloning cosmos-genesis-tinkerer"
cd ~
git clone git@github.com:hyphacoop/cosmos-genesis-tinkerer.git
cd cosmos-genesis-tinkerer/
git checkout $gh_branch

# Get version number using gaiad version
echo "Get running gaiad version"
chain_version=$( (su gaia -c "~gaia/.gaia/cosmovisor/current/bin/gaiad version") 2>&1) # Use stderr until gaiad use stdout
echo "Installed gaiad version is $chain_version"

# Export genesis
if [ ! -d mainnet-genesis-export ]
then
    mkdir mainnet-genesis-export
fi
echo "Export genesis"
time su gaia -c "~gaia/.gaia/cosmovisor/current/bin/gaiad export --height $current_block" 2> "mainnet-genesis-export/mainnet-genesis_${current_block_time}_${chain_version}_${current_block}.json"

echo "Tinkering exported genesis"
pip3 install -r requirements.txt
ln -s "$PWD/mainnet-genesis-export/mainnet-genesis_${current_block_time}_${chain_version}_${current_block}.json" "tests/mainnet_genesis.json"
time python3 ./example_mainnet_genesis.py
rm tests/mainnet_genesis.json
if [ ! -d mainnet-genesis-tinkered ]
then
    mkdir mainnet-genesis-tinkered
fi
mv tinkered_genesis.json "mainnet-genesis-tinkered/tinkered-genesis_${current_block_time}_${chain_version}_${current_block}.json"

# Compress files
echo "Compressing mainnet-genesis-export/mainnet-genesis_${current_block_time}_${chain_version}_${current_block}.json"
gzip "mainnet-genesis-export/mainnet-genesis_${current_block_time}_${chain_version}_${current_block}.json"
echo "Compressing mainnet-genesis-tinkered/tinkered-genesis_${current_block_time}_${chain_version}_${current_block}.json"
gzip "mainnet-genesis-tinkered/tinkered-genesis_${current_block_time}_${chain_version}_${current_block}.json"

# Upload to files.polypore.xyz
echo "Uploading exported Mainnet genesis to files.polypore.xyz"
scp mainnet-genesis-export/mainnet-genesis_${current_block_time}_${chain_version}_${current_block}.json.gz gh-actions@files.polypore.xyz:/var/www/html/genesis/mainnet-genesis-export/
echo "Uploading Tinkered Mainnet genesis to files.polypore.xyz"
scp mainnet-genesis-tinkered/tinkered-genesis_${current_block_time}_${chain_version}_${current_block}.json.gz gh-actions@files.polypore.xyz:/var/www/html/genesis/mainnet-genesis-tinkered/

# Update latest file symlinks
ssh gh-actions@files.polypore.xyz ln -sf /var/www/html/genesis/mainnet-genesis-export/mainnet-genesis_${current_block_time}_${chain_version}_${current_block}.json.gz /var/www/html/genesis/mainnet-genesis-export/latest_v$(echo $chain_version | awk -F "." '{ print substr($1,2) }').json.gz
ssh gh-actions@files.polypore.xyz ln -sf /var/www/html/genesis/mainnet-genesis-tinkered/tinkered-genesis_${current_block_time}_${chain_version}_${current_block}.json.gz /var/www/html/genesis/mainnet-genesis-tinkered/latest_v$(echo $chain_version | awk -F "." '{ print substr($1,2) }').json.gz

# cleanup
echo "Cleanup ~gaia/.gaia"
rm -rf ~gaia/.gaia

# Stateful upgrade archive
echo "Stateful upgrade archive"
cd ~
echo "Install Ansible"
pip3 install ansible

echo "Clone cosmos-ansible"
git clone https://github.com/hyphacoop/cosmos-ansible.git
cd cosmos-ansible
git checkout $gh_ansible_branch
sed -i '/^\[defaults\]/s/$/\ntransport = local/' ansible.cfg

echo "Configure cosmovisor service to not auto restart"
sed -e '/RestartSec=3/d ; s/Restart=always/Restart=no/ ; s/DAEMON_RESTART_AFTER_UPGRADE=true/DAEMON_RESTART_AFTER_UPGRADE=false/' roles/node/templates/cosmovisor.service.j2 > cosmovisor.service.j2
mv cosmovisor.service.j2 roles/node/templates/cosmovisor.service.j2

echo "Configure inventory file"
sed -e '/genesis_url:/d' examples/inventory-local-genesis.yml > inventory.yml

echo "Starting chain with the new tinkered genesis"
ansible-playbook node.yml -i inventory.yml --extra-vars "\
target=local \
reboot=false \
api_enabled=true \
minimum_gas_prices=0.0025uatom \
chain_version=$chain_version \
chain_gov_testing=true \
priv_validator_key_file=examples/validator-keys/validator-40/priv_validator_key.json \
node_key_file=examples/validator-keys/validator-40/node_key.json \
chain_binary_source=release \
chain_binary_release=https://github.com/hyphacoop/cosmos-builds/releases/download/gaiad-v14.1.0-snappy/gaiad-v14.1.0-snappy
genesis_file=~/cosmos-genesis-tinkerer/mainnet-genesis-tinkered/tinkered-genesis_${current_block_time}_${chain_version}_${current_block}.json.gz"

echo "Waiting till gaiad is building blocks"
su gaia -c "tests/test_block_production.sh 127.0.0.1 26657 50 2100"
if [ $? -ne 0 ]
then
    echo "gaiad failed to build blocks!"
    build_block=0
else
    echo "gaiad is building blocks"
    build_block=1
fi

echo "Restoring validator key"
su gaia -c "echo \"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art\" | ~/go/bin/gaiad --output json keys add val --keyring-backend test --recover 2> ~/.gaia/validator.json" # Use stderr until gaiad use stdout

if [ $build_block -eq 1 ]
then
    echo "Get current height"
    current_block=$(curl -s 127.0.0.1:26657/block | jq -r .result.block.header.height)
    upgrade_height=$(($current_block+100))

    echo "Submitting the upgrade proposal"
    proposal="~/go/bin/gaiad --output json tx gov submit-proposal software-upgrade $cosmos_upgrade_name --from val --keyring-backend test --upgrade-height $upgrade_height --upgrade-info 'Test' --title gaia-upgrade --description 'test' --chain-id local-testnet --deposit 10uatom --fees 1000uatom --yes -b block"
    echo $proposal
    txhash=$(su gaia -c "$proposal | jq -r .txhash")

    echo "Wait for the proposal to go on chain"
    sleep 8

    echo "Get proposal ID from txhash"
    proposal_id=$(su gaia -c "~/go/bin/gaiad --output json q tx $txhash | jq -r '.logs[].events[] | select(.type==\"submit_proposal\") | .attributes[] | select(.key==\"proposal_id\") | .value'")

    # Vote yes on the proposal
    echo "Submitting the \"yes\" vote to proposal $proposal_id"
    vote="~/go/bin/gaiad tx gov vote $proposal_id yes --from val --keyring-backend test --chain-id local-testnet --fees 1000uatom --yes"
    echo $vote
    su gaia -c "$vote"


    # Wait for the voting period to be over
    echo "Waiting for the voting period to end..."
    sleep 8

    echo "Upgrade proposal $proposal_id status:"
    su gaia -c "~/go/bin/gaiad q gov proposal $proposal_id --output json | jq '.status'"

    # Wait until the service is stopped
    echo "Cosmovisor should stop at height $upgrade_height"
    cosmovisor=0
    set +e
    while [ $cosmovisor -eq 0 ]
    do
        sleep 5
        curl -s 127.0.0.1:26657/block | jq -r .result.block.header.height
        systemctl --quiet is-active cosmovisor
        cosmovisor=$?
    done
    set -e

    # Archive .gaia
    echo "Archiving .gaia"
    cd ~gaia
    tar cfz $chain_version-$upgrade_height-stateful-upgrade.tar.gz .gaia

    # Upload to files.polypore.xyz
    echo "Uploading $chain_version-$upgrade_height-stateful-upgrade.tar.gz to files.polypore.xyz"
    scp $chain_version-$upgrade_height-stateful-upgrade.tar.gz gh-actions@files.polypore.xyz:/var/www/html/archived-state/

    # Update latest file symlinks
    echo "Updating latest file symlinks"
    ssh gh-actions@files.polypore.xyz ln -sf /var/www/html/archived-state/$chain_version-$upgrade_height-stateful-upgrade.tar.gz /var/www/html/archived-state/latest_v$(echo $chain_version | awk -F "." '{ print substr($1,2) }').tar.gz
fi

# Print current date and time
echo -n "Finished at: "
date

# Push log to cosmos-configurations-private repo
echo "Push log to cosmos-configurations-private repo"
cd ~
git clone git@github.com:hyphacoop/cosmos-configurations-private.git
cd cosmos-configurations-private
if [ ! -d logs/mainnet-export ]
then
    mkdir -p logs/mainnet-export
fi

# wait for log to be written
echo "End of log"
sleep 120
cp /root/export_genesis.log "logs/mainnet-export/mainnet-genesis_${start_date}_${chain_version}_${current_block}.log"
git add -A
git commit -m "Adding export log file"
git push origin main

# DESTROY the droplet from itself
curl -X DELETE -H "Authorization: Bearer {{ digitalocean_api_key }}" "https://api.digitalocean.com/v2/droplets/{{ droplet_id }}"

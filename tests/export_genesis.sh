#!/bin/bash
set -x
set -e

gh_branch="export-genesis"
gh_user="hypha-bot"

# Stop cosmovisor
systemctl stop cosmovisor

# Use quicksync
apt-get install wget liblz4-tool aria2 bc -y

echo "#!/bin/bash
set -x
set -e
cd ~/.gaia
URL=\$(curl https://quicksync.io/cosmos.json|jq -r '.[] |select(.file=="cosmoshub-4-pruned")|.url')
aria2c -x5 \$URL
wget https://raw.githubusercontent.com/chainlayer/quicksync-playbooks/master/roles/quicksync/files/checksum.sh
chmod +x checksum.sh
wget \$URL.checksum
curl -s https://lcd-cosmos.cosmostation.io/txs/\$(curl -s \$URL.hash)|jq -r '.tx.value.memo'|sha512sum -c
./checksum.sh \$(basename \$URL) check
lz4 -d \$(basename \$URL) | tar xf -
rm \$(basename \$URL)
if [ ! -d cosmovisor/upgrades ]
then
    mkdir -p cosmovisor/upgrades/v7-Theta/bin
    cp cosmovisor/genesis/bin/gaiad cosmovisor/upgrades/v7-Theta/bin/gaiad
fi
" > ~gaia/quicksync.sh
chmod +x ~gaia/quicksync.sh
su gaia -c '~gaia/quicksync.sh'

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
	echo "catching up"
	sleep 5
done
echo "Done catching up"

# Get current block height
current_block=$(curl -s 127.0.0.1:26657/block | jq -r .result.block.header.height)
echo "Current block: $current_block"

# Stop cosmovisor before exporting
echo "stop cosmovisor"
systemctl stop cosmovisor

# Clone cosmos-genesis-tinkerer
echo "Cloneing cosmos-genesis-tinkerer"
cd ~
if [ ! -f ~/.ssh ]
then
    mkdir -m 700 ~/.ssh
fi

ssh-keyscan github.com >> ~/.ssh/known_hosts
git config --global credential.helper store
git config --global user.name "$gh_user"
git config --global user.email $gh_user@users.noreply.github.com
git clone git@github.com:hyphacoop/cosmos-genesis-tinkerer.git
cd cosmos-genesis-tinkerer/
git checkout $gh_branch

# Export genesis
if [ ! -d mainnet-genesis-export ]
then
    mkdir mainnet-genesis-export
fi
echo "Export genesis"
cd mainnet-genesis-export
su gaia -c "~gaia/.gaia/cosmovisor/current/bin/gaiad export --height $current_block" 2> mainnet_genesis_$current_block.json
gzip mainnet_genesis_$current_block.json

# Push to github
echo "push to github"
git add -A
git commit -m "Adding mainnet genesis at height $current_block"
git push origin $gh_branch

# DESTROY the droplet from itself
curl -X DELETE -H "Authorization: Bearer {{ digitalocean_api_key }}" "https://api.digitalocean.com/v2/droplets/{{ droplet_id }}"

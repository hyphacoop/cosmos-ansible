#!/bin/bash
set -e

gh_branch="export-genesis"
gh_user="hypha-bot"

# Store current date and time
start_date=$(date +"%Y%m%d_%H-%M-%S")

# Stop cosmovisor
echo "Stopping cosmovisor"
systemctl stop cosmovisor

# Use quicksync as statesync is not reliable
echo "Installing utils needed to quicksync"
apt-get install wget liblz4-tool aria2 bc -y

echo "Creating script for gaia user"
echo "#!/bin/bash
echo \"cd ~/.gaia\"
cd ~/.gaia
echo \"Set URL\"
URL=\$(curl https://quicksync.io/cosmos.json|jq -r '.[] |select(.file==\"cosmoshub-4-pruned\")|.url')
echo \"URL set to: \$URL\"
echo \"Starting download\"
aria2c -x5 \$URL
echo \"Download checksum script\"
wget https://raw.githubusercontent.com/chainlayer/quicksync-playbooks/master/roles/quicksync/files/checksum.sh
chmod +x checksum.sh
echo \"Download \$URL.checksum\"
wget \$URL.checksum
echo \"Get sha512sum\"
curl -s https://lcd-cosmos.cosmostation.io/txs/\$(curl -s \$URL.hash)|jq -r '.tx.value.memo'|sha512sum -c
echo \"Checking hash of download\"
./checksum.sh \$(basename \$URL) check
if [ \$? -ne 0 ]
then
	echo "Checksum FAILED falling back to statesync"
	rm \$(basename \$URL)
else
	echo \"Execting \$(basename \$URL)\"
	lz4 -d \$(basename \$URL) | tar xf -
	echo \"Removing \$(basename \$URL)\"
	rm \$(basename \$URL)
fi
if [ ! -d cosmovisor/upgrades ]
then
    echo \"Creating cosmovisor/upgrades/v7-Theta/bin directory\"
    mkdir -p cosmovisor/upgrades/v7-Theta/bin
    cp cosmovisor/genesis/bin/gaiad cosmovisor/upgrades/v7-Theta/bin/gaiad
fi
" > ~gaia/quicksync.sh
chmod +x ~gaia/quicksync.sh
echo "Running ~gaia/quicksync.sh as gaia user"
su gaia -c '~gaia/quicksync.sh'

ssh-keyscan github.com >> ~/.ssh/known_hosts

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
cp /root/export_genesis.log logs/mainnet-export/$date\_export_genesis.log
git add -A
git commit -m "Adding export log file"
git push origin main

# DESTROY the droplet from itself
curl -X DELETE -H "Authorization: Bearer {{ digitalocean_api_key }}" "https://api.digitalocean.com/v2/droplets/{{ droplet_id }}"

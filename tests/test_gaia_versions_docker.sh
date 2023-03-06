#!/bin/bash
# Runs fresh upgrade tests using Debian Docker container

chain_version=$1
upgrade_version=$2
set -e

apt -y update
apt -y dist-upgrade
apt -y install sudo curl wget git python3 python3-distutils screen jq python-is-python3

# install pip3
wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py
python3 /tmp/get-pip.py

# install ansible
pip3 install ansible

# git clone https://github.com/hyphacoop/cosmos-ansible.git
# cd /cosmos-ansible
# git checkout docker-tests

echo "transport = local" >> ansible.cfg
ansible-playbook node.yml -i examples/inventory-local.yml --extra-vars "target=local \
reboot=false \
chain_version=$chain_version \
chain_binary_source=release \
chain_gov_testing=true \
node_user=gaia \
cosmovisor_invariants_flag='' \
chain_start=false \
faucet_setup_nginx=false \
faucet_start=false"

export DAEMON_NAME=gaiad \
DAEMON_HOME=/home/gaia/.gaia \
DAEMON_ALLOW_DOWNLOAD_BINARIES=true \
DAEMON_RESTART_AFTER_UPGRADE=true \
DAEMON_LOG_BUFFER_SIZE=512 \
UNSAFE_SKIP_BACKUP=true

# create script for cosmovisor
echo "while true; do su gaia -c \"~/go/bin/cosmovisor run start --home /home/gaia/.gaia\"; sleep 1; done" > ~/cosmovisor.sh
chmod +x /cosmos-ansible/cosmovisor.sh

screen -L -Logfile /root/cosmovisor.log -S cosmovisor -d -m bash '/cosmos-ansible/cosmovisor.sh'

# tests
chown -R gaia:gaia /cosmos-ansible
# Check blocks are being produced
su gaia -c "tests/test_block_production.sh 127.0.0.1 26657 10"
# Test software upgrade
su gaia -c "tests/test_software_upgrade.sh 127.0.0.1 26657 $upgrade_version"
# Happy path - transaction testing
su gaia -c "tests/test_tx_fresh.sh"

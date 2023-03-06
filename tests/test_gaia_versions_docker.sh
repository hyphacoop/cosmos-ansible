#!/bin/bash
# Runs fresh upgrade tests using Debian Docker container

chain_version=$1
upgrade_version=$2

set -e

# Update system
echo "Update / upgrade system"
apt -y update
apt -y dist-upgrade
apt -y install sudo curl wget git python3 python3-distutils screen jq python-is-python3

# Install pip3
echo "Installing pip3"
wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py
python3 /tmp/get-pip.py

# Install ansible
echo "Installing ansible"
pip3 install ansible

# git clone https://github.com/hyphacoop/cosmos-ansible.git
# cd /cosmos-ansible
# git checkout docker-tests

# Run ansible playbook
echo "cd /cosmos-ansible"
cd /cosmos-ansible
echo "ls -al"
ls -al
echo "Configure ansible.cfg"
echo "transport = local" >> ansible.cfg
echo "Running Ansible playbook"
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

echo "Setting env"
export DAEMON_NAME=gaiad \
DAEMON_HOME=/home/gaia/.gaia \
DAEMON_ALLOW_DOWNLOAD_BINARIES=true \
DAEMON_RESTART_AFTER_UPGRADE=true \
DAEMON_LOG_BUFFER_SIZE=512 \
UNSAFE_SKIP_BACKUP=true

# Create script for cosmovisor
echo "Creating script for cosmovisor"
echo "while true; do su gaia -c \"~/go/bin/cosmovisor run start --home /home/gaia/.gaia\"; sleep 1; done" > /cosmos-ansible/cosmovisor.sh
chmod +x /cosmos-ansible/cosmovisor.sh

# Run cosmovisor in screen session
screen -L -Logfile /root/cosmovisor.log -S cosmovisor -d -m bash '/cosmos-ansible/cosmovisor.sh'

# Tests
chown -R gaia:gaia /cosmos-ansible
# Check blocks are being produced
echo "Check blocks are being produced..."
su gaia -c "tests/test_block_production.sh 127.0.0.1 26657 10"
# Test software upgrade
echo "Test software upgrade..."
su gaia -c "tests/test_software_upgrade.sh 127.0.0.1 26657 $upgrade_version"
# Happy path - transaction testing
echo "Happy path - transaction testing..."
su gaia -c "tests/test_tx_fresh.sh"

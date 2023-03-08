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
mkdir /cosmos-ansible/artifact
echo "Starting cosmovisor"
screen -L -Logfile /cosmos-ansible/artifact/cosmovisor.log -S cosmovisor -d -m bash '/cosmos-ansible/cosmovisor.sh'
# set screen to flush log to 0
screen -r cosmovisor -p0 -X logfile flush 0

# Tests
set +e
chown -R gaia:gaia /cosmos-ansible
# Check blocks are being produced
echo "Check blocks are being produced..."
su gaia -c "tests/test_block_production.sh 127.0.0.1 26657 10"
if [ $? -ne 0 ]
then
    echo "gaiad not producing blocks"
    screen -XS cosmovisor quit
    sleep 5
    exit 1
fi
# Test software upgrade
echo "Test software upgrade..."
su gaia -c "tests/test_software_upgrade.sh 127.0.0.1 26657 $upgrade_version"
if [ $? -ne 0 ]
then
    echo "test software upgrade failed"
    screen -XS cosmovisor quit
    sleep 5
    exit 1
fi
# Happy path - transaction testing
echo "Happy path - transaction testing..."
su gaia -c "tests/test_tx_fresh.sh"
if [ $? -ne 0 ]
then
    echo "Happy path test failed"
    screen -XS cosmovisor quit
    sleep 5
    exit 1
fi

screen -XS cosmovisor quit
sleep 5

#!/bin/bash
# 1. Set up a two-validator provider chain.
set -x
source ~/env/bin/activate

# Download archived home directory
echo "Initializing node homes..."
echo "Downloading archived state"
wget -nv -O $HOME/archived-state.gz $ARCHIVE_URL
echo "Extracting archive"
mkdir -p $HOME_1 
tar xf $HOME/archived-state.gz -C $HOME_1 --strip-components=1

# echo "Patching genesis file for fast governance..."
# jq -r ".app_state.gov.voting_params.voting_period = \"$VOTING_PERIOD\"" $HOME_1/config/genesis.json  > ./voting.json
# jq -r ".app_state.gov.deposit_params.min_deposit[0].amount = \"1\"" ./voting.json > ./gov.json
# mv ./gov.json $HOME_1/config/genesis.json

# Install Gaia binary
CHAIN_BINARY_URL=$DOWNLOAD_URL
echo "Installing Gaia..."
mkdir -p $HOME/go/bin
wget -nv $CHAIN_BINARY_URL -O $HOME/go/bin/$CHAIN_BINARY
chmod +x $HOME/go/bin/$CHAIN_BINARY

# Printing Gaia binary checksum
echo GAIA_CHECKSUM: $(sha256sum $HOME/go/bin/$CHAIN_BINARY)

echo "Patching config files..."
# app.toml
# minimum_gas_prices
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"0.0025$DENOM\"^" $HOME_1/config/app.toml

# Enable API
toml set --toml-path $HOME_1/config/app.toml api.enable true

# Set different ports for api
toml set --toml-path $HOME_1/config/app.toml api.address "tcp://0.0.0.0:$VAL1_API_PORT"

# Set different ports for grpc
toml set --toml-path $HOME_1/config/app.toml grpc.address "0.0.0.0:$VAL1_GRPC_PORT"

# Turn off grpc web
toml set --toml-path $HOME_1/config/app.toml grpc-web.enable false

# config.toml
# Replace fast_sync with block_sync
sed -i -e "s\fast_sync\block_sync\g" $HOME_1/config/config.toml

# Set different ports for rpc
toml set --toml-path $HOME_1/config/config.toml rpc.laddr "tcp://0.0.0.0:$VAL1_RPC_PORT"

# Set different ports for rpc pprof
toml set --toml-path $HOME_1/config/config.toml rpc.pprof_laddr "localhost:$VAL1_PPROF_PORT"

# Set different ports for p2p
toml set --toml-path $HOME_1/config/config.toml p2p.laddr "tcp://0.0.0.0:$VAL1_P2P_PORT"

# Allow duplicate IPs in p2p
toml set --toml-path $HOME_1/config/config.toml p2p.allow_duplicate_ip true

# Set client ports for rpc
toml set --toml-path $HOME_1/config/client.toml node "tcp://localhost:$VAL1_RPC_PORT"

# Set client chain-id
toml set --toml-path $HOME_1/config/client.toml chain-id "$CHAIN_ID"

# Create self-delegation accounts
echo $MNEMONIC_2 | $CHAIN_BINARY keys add $MONIKER_2 --keyring-backend test --home $HOME_1 --recover

echo "Setting up services..."
echo "Creating script for $CHAIN_BINARY"
echo "while true; do $HOME/go/bin/$CHAIN_BINARY start --home $HOME_1; sleep 1; done" > $HOME/$PROVIDER_SERVICE_1.sh
chmod +x $HOME/$PROVIDER_SERVICE_1.sh

# Run service in screen session
if [ ! -d $HOME/artifact ]
then
    mkdir $HOME/artifact
fi

echo "Starting $CHAIN_BINARY"
screen -L -Logfile $HOME/artifact/$PROVIDER_SERVICE_1.log -S $PROVIDER_SERVICE_1 -d -m bash $HOME/$PROVIDER_SERVICE_1.sh
# set screen to flush log to 0
screen -r $PROVIDER_SERVICE_1 -p0 -X logfile flush 0

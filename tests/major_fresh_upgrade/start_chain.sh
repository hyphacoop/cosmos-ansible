#!/bin/bash
# 1. Set up a two-validator provider chain.

# Install wget and jq
sudo apt-get install curl jq wget -y

# Install Gaia binary
CHAIN_BINARY_URL=https://github.com/cosmos/gaia/releases/download/$START_VERSION/gaiad-$START_VERSION-linux-amd64
echo "Installing Gaia..."
mkdir -p $HOME/go/bin
wget $CHAIN_BINARY_URL -O $HOME/go/bin/$CHAIN_BINARY
chmod +x $HOME/go/bin/$CHAIN_BINARY

# Initialize home directories
echo "Initializing node homes..."
$CHAIN_BINARY config chain-id $CHAIN_ID --home $HOME_1
$CHAIN_BINARY config keyring-backend test --home $HOME_1
$CHAIN_BINARY config broadcast-mode block --home $HOME_1
$CHAIN_BINARY config node tcp://localhost:$VAL1_RPC_PORT --home $HOME_1
$CHAIN_BINARY init $MONIKER_1 --chain-id $CHAIN_ID --home $HOME_1

# Create self-delegation accounts
echo $MNEMONIC_1 | $CHAIN_BINARY keys add $MONIKER_1 --keyring-backend test --home $HOME_1 --recover

# Update genesis file with right denom
sed -i s%stake%$DENOM%g $HOME_1/config/genesis.json

# Add funds to accounts
$CHAIN_BINARY add-genesis-account $MONIKER_1 $VAL_FUNDS$DENOM --home $HOME_1

echo "Creating and collecting gentxs..."
mkdir -p $HOME_1/config/gentx
$CHAIN_BINARY gentx $MONIKER_1 $VAL_STAKE$DENOM --pubkey "$($CHAIN_BINARY tendermint show-validator --home $HOME_1)" --node-id $($CHAIN_BINARY tendermint show-node-id --home $HOME_1) --moniker $MONIKER_1 --chain-id $CHAIN_ID --home $HOME_1 --output-document $HOME_1/config/gentx/$MONIKER_1-gentx.json
$CHAIN_BINARY collect-gentxs --home $HOME_1

echo "Patching genesis file for fast governance..."
jq -r ".app_state.gov.voting_params.voting_period = \"$VOTING_PERIOD\"" $HOME_1/config/genesis.json  > ./voting.json
mv ./voting.json $HOME_1/config/genesis.json

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
# Set different ports for rpc
toml set --toml-path $HOME_1/config/config.toml rpc.laddr "tcp://0.0.0.0:$VAL1_RPC_PORT"

# Set different ports for rpc pprof
toml set --toml-path $HOME_1/config/config.toml rpc.pprof_laddr "localhost:$VAL1_PPROF_PORT"

# Set different ports for p2p
toml set --toml-path $HOME_1/config/config.toml p2p.laddr "tcp://0.0.0.0:$VAL1_P2P_PORT"

# Allow duplicate IPs in p2p
toml set --toml-path $HOME_1/config/config.toml p2p.allow_duplicate_ip true

echo "Setting up services..."

sudo touch /etc/systemd/system/$PROVIDER_SERVICE_1
echo "[Unit]"                               | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1
echo "Description=Gaia service"       | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo ""                                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "ExecStart=$HOME/go/bin/$CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $HOME_1" | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "Restart=no"                       | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo ""                                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a

sudo systemctl daemon-reload
sudo systemctl enable $PROVIDER_SERVICE_1 --now


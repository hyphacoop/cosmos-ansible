#!/bin/bash
# Set up a one-validator Stride v11 chain.

# Install Stride binary
echo "Installing Stride..."
wget $STRIDE_SOV_CHAIN_BINARY_URL -O $HOME/go/bin/$STRIDE_CHAIN_BINARY -q
chmod +x $HOME/go/bin/$STRIDE_CHAIN_BINARY

# Initialize home directories
echo "Initializing node homes..."
$STRIDE_CHAIN_BINARY config chain-id $STRIDE_CHAIN_ID --home $STRIDE_HOME_1
$STRIDE_CHAIN_BINARY config keyring-backend test --home $STRIDE_HOME_1
$STRIDE_CHAIN_BINARY config node tcp://localhost:$STRIDE_RPC_1 --home $STRIDE_HOME_1
$STRIDE_CHAIN_BINARY init $MONIKER_1 --chain-id $STRIDE_CHAIN_ID --home $STRIDE_HOME_1

$STRIDE_CHAIN_BINARY config chain-id $STRIDE_CHAIN_ID --home $STRIDE_HOME_2
$STRIDE_CHAIN_BINARY config keyring-backend test --home $STRIDE_HOME_2
$STRIDE_CHAIN_BINARY config node tcp://localhost:$STRIDE_RPC_2 --home $STRIDE_HOME_2
$STRIDE_CHAIN_BINARY init $MONIKER_2 --chain-id $STRIDE_CHAIN_ID --home $STRIDE_HOME_2

# Copy existing keys
cp $HOME_1/config/node_key.json $STRIDE_HOME_1/config/node_key.json
cp $HOME_2/config/node_key.json $STRIDE_HOME_2/config/node_key.json
cp $HOME_1/config/priv_validator_key.json $STRIDE_HOME_1/config/priv_validator_key.json
cp $HOME_2/config/priv_validator_key.json $STRIDE_HOME_2/config/priv_validator_key.json

# Create self-delegation accounts
echo $MNEMONIC_1 | $STRIDE_CHAIN_BINARY keys add $MONIKER_1 --keyring-backend test --recover --home $STRIDE_HOME_1
echo $MNEMONIC_2 | $STRIDE_CHAIN_BINARY keys add $MONIKER_2 --keyring-backend test --recover --home $STRIDE_HOME_1
echo $MNEMONIC_4 | $STRIDE_CHAIN_BINARY keys add $MONIKER_4 --keyring-backend test --recover --home $STRIDE_HOME_1
echo $MNEMONIC_5 | $STRIDE_CHAIN_BINARY keys add $MONIKER_5 --keyring-backend test --recover --home $STRIDE_HOME_1
echo $MNEMONIC_2 | $STRIDE_CHAIN_BINARY keys add $MONIKER_2 --keyring-backend test --recover --home $STRIDE_HOME_2

echo "Patching genesis with ustrd denom..."
jq '.app_state.crisis.constant_fee.denom = "ustrd"' $STRIDE_HOME_1/config/genesis.json > stride-genesis-1.json
jq '.app_state.gov.params.min_deposit[0].denom = "ustrd"' stride-genesis-1.json > stride-genesis-2.json
jq '.app_state.mint.params.mint_denom = "ustrd"' stride-genesis-2.json > stride-genesis-3.json
jq '.app_state.staking.params.bond_denom = "ustrd"' stride-genesis-3.json > stride-genesis-4.json

echo "Patching genesis file for fast governance..."
jq '(.app_state.epochs.epochs[] | select(.identifier=="day") ).duration = "120s"' stride-genesis-4.json  > stride-genesis-5.json
jq '(.app_state.epochs.epochs[] | select(.identifier=="stride_epoch") ).duration = "120s"' stride-genesis-5.json  > stride-genesis-6.json
jq '.app_state.gov.voting_params.voting_period = "10s"' stride-genesis-6.json  > stride-genesis-7.json
jq '.app_state.gov.params.voting_period = "10s"' stride-genesis-7.json  > stride-genesis-8.json

echo "Setting slashing to 100000 missed blocks..."
jq -r '.app_state.slashing.params.signed_blocks_window = "100000"' stride-genesis-8.json > consumer-slashing.json
cp consumer-slashing.json $STRIDE_HOME_1/config/genesis.json

echo "Adding funds to accounts..."
$STRIDE_CHAIN_BINARY add-genesis-account $MONIKER_1 1000000000$STRIDE_DENOM --home $STRIDE_HOME_1
$STRIDE_CHAIN_BINARY add-genesis-account $MONIKER_4 1000000000$STRIDE_DENOM --home $STRIDE_HOME_1
$STRIDE_CHAIN_BINARY add-genesis-account $MONIKER_5 1000000000$STRIDE_DENOM --home $STRIDE_HOME_1

echo "Creating and collecting gentxs..."
mkdir -p $STRIDE_HOME_1/config/gentx
$STRIDE_CHAIN_BINARY gentx $MONIKER_1 10000000$STRIDE_DENOM --pubkey "$($STRIDE_CHAIN_BINARY tendermint show-validator --home $STRIDE_HOME_1)" --node-id $($STRIDE_CHAIN_BINARY tendermint show-node-id --home $STRIDE_HOME_1)  --home $STRIDE_HOME_1 --moniker $MONIKER_1 --chain-id $STRIDE_CHAIN_ID --output-document $STRIDE_HOME_1/config/gentx/$MONIKER_1-gentx.json
$STRIDE_CHAIN_BINARY collect-gentxs --home $STRIDE_HOME_1

echo "Distributing genesis file..."
cp $STRIDE_HOME_1/config/genesis.json $STRIDE_HOME_2/config/genesis.json

echo "Patching config files..."
# app.toml
# minimum_gas_prices
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"0.0025$STRIDE_DENOM\"^" $STRIDE_HOME_1/config/app.toml
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"0.0025$STRIDE_DENOM\"^" $STRIDE_HOME_2/config/app.toml

# Enable API
toml set --toml-path $STRIDE_HOME_1/config/app.toml api.enable true
toml set --toml-path $STRIDE_HOME_2/config/app.toml api.enable true

# Set different ports for api
toml set --toml-path $STRIDE_HOME_1/config/app.toml api.address "tcp://0.0.0.0:$STRIDE_API_1"
toml set --toml-path $STRIDE_HOME_2/config/app.toml api.address "tcp://0.0.0.0:$STRIDE_API_2"

# Set different ports for grpc
toml set --toml-path $STRIDE_HOME_1/config/app.toml grpc.address "0.0.0.0:$STRIDE_GRPC_1"
toml set --toml-path $STRIDE_HOME_2/config/app.toml grpc.address "0.0.0.0:$STRIDE_GRPC_2"

# Turn off grpc web
toml set --toml-path $STRIDE_HOME_1/config/app.toml grpc-web.enable false
toml set --toml-path $STRIDE_HOME_2/config/app.toml grpc-web.enable false

# config.toml
# Set different ports for rpc
toml set --toml-path $STRIDE_HOME_1/config/config.toml rpc.laddr "tcp://0.0.0.0:$STRIDE_RPC_1"
toml set --toml-path $STRIDE_HOME_2/config/config.toml rpc.laddr "tcp://0.0.0.0:$STRIDE_RPC_2"

# Set different ports for rpc pprof
toml set --toml-path $STRIDE_HOME_1/config/config.toml rpc.pprof_laddr "localhost:$STRIDE_PPROF_1"
toml set --toml-path $STRIDE_HOME_2/config/config.toml rpc.pprof_laddr "localhost:$STRIDE_PPROF_2"

# Set different ports for p2p
toml set --toml-path $STRIDE_HOME_1/config/config.toml p2p.laddr "tcp://0.0.0.0:$STRIDE_P2P_1"
toml set --toml-path $STRIDE_HOME_2/config/config.toml p2p.laddr "tcp://0.0.0.0:$STRIDE_P2P_2"

echo "Setting a short commit timeout..."
seconds=s
toml set --toml-path $STRIDE_HOME_1/config/config.toml consensus.timeout_commit "$COMMIT_TIMEOUT$seconds"
toml set --toml-path $STRIDE_HOME_2/config/config.toml consensus.timeout_commit "$COMMIT_TIMEOUT$seconds"

# Allow duplicate IPs in p2p
toml set --toml-path $STRIDE_HOME_1/config/config.toml p2p.allow_duplicate_ip true
toml set --toml-path $STRIDE_HOME_2/config/config.toml p2p.allow_duplicate_ip true

# Set block_sync to false
toml set --toml-path $STRIDE_HOME_1/config/config.toml block_sync false
toml set --toml-path $STRIDE_HOME_2/config/config.toml block_sync false

echo "Setting persistent peers..."
VAL2_NODE_ID=$($STRIDE_CHAIN_BINARY tendermint show-node-id --home $STRIDE_HOME_2)
VAL2_PEER="$VAL2_NODE_ID@localhost:$STRIDE_P2P_2"
toml set --toml-path $STRIDE_HOME_1/config/config.toml p2p.persistent_peers "$VAL2_PEER"

echo "Setting up services..."

sudo touch /etc/systemd/system/$STRIDE_SERVICE_1
echo "[Unit]"                               | sudo tee /etc/systemd/system/$STRIDE_SERVICE_1
echo "Description=Stride1 service"       | sudo tee /etc/systemd/system/$STRIDE_SERVICE_1 -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$STRIDE_SERVICE_1 -a
echo ""                                     | sudo tee /etc/systemd/system/$STRIDE_SERVICE_1 -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$STRIDE_SERVICE_1 -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/$STRIDE_SERVICE_1 -a
echo "ExecStart=$HOME/go/bin/$STRIDE_CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $STRIDE_HOME_1" | sudo tee /etc/systemd/system/$STRIDE_SERVICE_1 -a
echo "Restart=no"                       | sudo tee /etc/systemd/system/$STRIDE_SERVICE_1 -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$STRIDE_SERVICE_1 -a
echo ""                                     | sudo tee /etc/systemd/system/$STRIDE_SERVICE_1 -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$STRIDE_SERVICE_1 -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$STRIDE_SERVICE_1 -a

sudo touch /etc/systemd/system/$STRIDE_SERVICE_2
echo "[Unit]"                               | sudo tee /etc/systemd/system/$STRIDE_SERVICE_2
echo "Description=Stride1 service"       | sudo tee /etc/systemd/system/$STRIDE_SERVICE_2 -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$STRIDE_SERVICE_2 -a
echo ""                                     | sudo tee /etc/systemd/system/$STRIDE_SERVICE_2 -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$STRIDE_SERVICE_2 -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/$STRIDE_SERVICE_2 -a
echo "ExecStart=$HOME/go/bin/$STRIDE_CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $STRIDE_HOME_2" | sudo tee /etc/systemd/system/$STRIDE_SERVICE_2 -a
echo "Restart=no"                       | sudo tee /etc/systemd/system/$STRIDE_SERVICE_2 -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$STRIDE_SERVICE_2 -a
echo ""                                     | sudo tee /etc/systemd/system/$STRIDE_SERVICE_2 -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$STRIDE_SERVICE_2 -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$STRIDE_SERVICE_2 -a

sudo systemctl daemon-reload
sudo systemctl enable $STRIDE_SERVICE_1 --now
# sudo systemctl enable $STRIDE_SERVICE_2 --now

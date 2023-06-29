#!/bin/bash
# Initialize a consumer chain

# echo "Stopping existing services..."
# sudo systemctl disable $CONSUMER_SERVICE_1 --now
# sudo systemctl disable $CONSUMER_SERVICE_2 --now
# rm -rf $CONSUMER_HOME_1
# rm -rf $CONSUMER_HOME_2

# wget $CONSUMER_CHAIN_BINARY_URL -O $HOME/go/bin/$CONSUMER_CHAIN_BINARY
# chmod +x $HOME/go/bin/$CONSUMER_CHAIN_BINARY

# Initialize home directories
echo "Initializing consumer homes..."
$CONSUMER_CHAIN_BINARY config chain-id $CONSUMER_CHAIN_ID --home $CONSUMER_HOME_1
$CONSUMER_CHAIN_BINARY config keyring-backend test --home $CONSUMER_HOME_1
$CONSUMER_CHAIN_BINARY config broadcast-mode block --home $CONSUMER_HOME_1
$CHAIN_BINARY config node tcp://localhost:$CON1_RPC_PORT --home $CONSUMER_HOME_1
$CONSUMER_CHAIN_BINARY init $MONIKER_1 --chain-id $CONSUMER_CHAIN_ID --home $CONSUMER_HOME_1

$CONSUMER_CHAIN_BINARY config chain-id $CONSUMER_CHAIN_ID --home $CONSUMER_HOME_2
$CONSUMER_CHAIN_BINARY config keyring-backend test --home $CONSUMER_HOME_2
$CONSUMER_CHAIN_BINARY config broadcast-mode block --home $CONSUMER_HOME_2
$CHAIN_BINARY config node tcp://localhost:$CON2_RPC_PORT --home $CONSUMER_HOME_2
$CONSUMER_CHAIN_BINARY init $MONIKER_2 --chain-id $CONSUMER_CHAIN_ID --home $CONSUMER_HOME_2

echo "Copying keys from provider nodes to consumer ones..."
cp $HOME_1/config/priv_validator_key.json $CONSUMER_HOME_1/config/priv_validator_key.json
cp $HOME_1/config/node_key.json $CONSUMER_HOME_1/config/node_key.json
cp $HOME_2/config/priv_validator_key.json $CONSUMER_HOME_2/config/priv_validator_key.json
cp $HOME_2/config/node_key.json $CONSUMER_HOME_2/config/node_key.json

# Update genesis file with right denom
sed -i s%stake%$CONSUMER_DENOM%g $CONSUMER_HOME_1/config/genesis.json

# Create self-delegation accounts
echo $MNEMONIC_1 | $CONSUMER_CHAIN_BINARY keys add $MONIKER_1 --keyring-backend test --home $CONSUMER_HOME_1 --recover
echo $MNEMONIC_2 | $CONSUMER_CHAIN_BINARY keys add $MONIKER_2 --keyring-backend test --home $CONSUMER_HOME_1 --recover
echo $MNEMONIC_4 | $CONSUMER_CHAIN_BINARY keys add $MONIKER_4 --keyring-backend test --home $CONSUMER_HOME_1 --recover
echo $MNEMONIC_2 | $CONSUMER_CHAIN_BINARY keys add $MONIKER_2 --keyring-backend test --home $CONSUMER_HOME_2 --recover


# Add funds to accounts
$CONSUMER_CHAIN_BINARY add-genesis-account $MONIKER_1 $VAL_FUNDS$CONSUMER_DENOM --home $CONSUMER_HOME_1
$CONSUMER_CHAIN_BINARY add-genesis-account $MONIKER_2 $VAL_FUNDS$CONSUMER_DENOM --home $CONSUMER_HOME_1
$CONSUMER_CHAIN_BINARY add-genesis-account $MONIKER_4 $VAL_FUNDS$CONSUMER_DENOM --home $CONSUMER_HOME_1

echo "Patching config files..."
# app.toml
# minimum_gas_prices
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"0$CONSUMER_DENOM\"^" $CONSUMER_HOME_1/config/app.toml
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"0$CONSUMER_DENOM\"^" $CONSUMER_HOME_2/config/app.toml

# Enable API
toml set --toml-path $CONSUMER_HOME_1/config/app.toml api.enable true
toml set --toml-path $CONSUMER_HOME_2/config/app.toml api.enable true

# Set different ports for api
toml set --toml-path $CONSUMER_HOME_1/config/app.toml api.address "tcp://0.0.0.0:$CON1_API_PORT"
toml set --toml-path $CONSUMER_HOME_2/config/app.toml api.address "tcp://0.0.0.0:$CON2_API_PORT"

# Set different ports for grpc
toml set --toml-path $CONSUMER_HOME_1/config/app.toml grpc.address "0.0.0.0:$CON1_GRPC_PORT"
toml set --toml-path $CONSUMER_HOME_2/config/app.toml grpc.address "0.0.0.0:$CON2_GRPC_PORT"

# Turn off grpc web
toml set --toml-path $CONSUMER_HOME_1/config/app.toml grpc-web.enable false
toml set --toml-path $CONSUMER_HOME_2/config/app.toml grpc-web.enable false

# config.toml
# Set different ports for rpc
toml set --toml-path $CONSUMER_HOME_1/config/config.toml rpc.laddr "tcp://0.0.0.0:$CON1_RPC_PORT"
toml set --toml-path $CONSUMER_HOME_2/config/config.toml rpc.laddr "tcp://0.0.0.0:$CON2_RPC_PORT"

# Set different ports for rpc pprof
toml set --toml-path $CONSUMER_HOME_1/config/config.toml rpc.pprof_laddr "localhost:$CON1_PPROF_PORT"
toml set --toml-path $CONSUMER_HOME_2/config/config.toml rpc.pprof_laddr "localhost:$CON2_PPROF_PORT"

# Set different ports for p2p
toml set --toml-path $CONSUMER_HOME_1/config/config.toml p2p.laddr "tcp://0.0.0.0:$CON1_P2P_PORT"
toml set --toml-path $CONSUMER_HOME_2/config/config.toml p2p.laddr "tcp://0.0.0.0:$CON2_P2P_PORT"

# Set persistent peers in p2p2
PEERS="$($CONSUMER_CHAIN_BINARY tendermint show-node-id --home $CONSUMER_HOME_2)@127.0.0.1:$CON2_P2P_PORT"
toml set --toml-path $CONSUMER_HOME_1/config/config.toml p2p.persistent_peers $PEERS

# Allow duplicate IPs in p2p
toml set --toml-path $CONSUMER_HOME_1/config/config.toml p2p.allow_duplicate_ip true
toml set --toml-path $CONSUMER_HOME_2/config/config.toml p2p.allow_duplicate_ip true

echo "Setting up services..."

sudo rm /etc/systemd/system/$CONSUMER_SERVICE_1
sudo touch /etc/systemd/system/$CONSUMER_SERVICE_1
echo "[Unit]"                               | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1
echo "Description=Consumer service"       | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1 -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1 -a
echo ""                                     | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1 -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1 -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1 -a
echo "ExecStart=$HOME/go/bin/$CONSUMER_CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $CONSUMER_HOME_1" | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1 -a
echo "Restart=no"                       | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1 -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1 -a
echo ""                                     | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1 -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1 -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1 -a

sudo rm /etc/systemd/system/$CONSUMER_SERVICE_2
sudo touch /etc/systemd/system/$CONSUMER_SERVICE_2
echo "[Unit]"                               | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2
echo "Description=Consumer service"       | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2 -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2 -a
echo ""                                     | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2 -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2 -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2 -a
echo "ExecStart=$HOME/go/bin/$CONSUMER_CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $CONSUMER_HOME_2" | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2 -a
echo "Restart=no"                       | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2 -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2 -a
echo ""                                     | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2 -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2 -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2 -a

sudo systemctl daemon-reload

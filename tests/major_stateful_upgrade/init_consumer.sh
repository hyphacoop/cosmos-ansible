#!/bin/bash
# Initialize a consumer chain
source ~/env/bin/activate

echo "Running with $CONSUMER_CHAIN_BINARY."

# Initialize home directories
echo "Initializing consumer homes..."
$CONSUMER_CHAIN_BINARY config chain-id $CONSUMER_CHAIN_ID --home $CONSUMER_HOME_1
$CONSUMER_CHAIN_BINARY config keyring-backend test --home $CONSUMER_HOME_1
$CHAIN_BINARY config node tcp://localhost:$CON1_RPC_PORT --home $CONSUMER_HOME_1
$CONSUMER_CHAIN_BINARY init $MONIKER_1 --chain-id $CONSUMER_CHAIN_ID --home $CONSUMER_HOME_1

echo "Copying keys from provider nodes to consumer ones..."
cp $HOME_1/config/priv_validator_key.json $CONSUMER_HOME_1/config/priv_validator_key.json
cp $HOME_1/config/node_key.json $CONSUMER_HOME_1/config/node_key.json

# Update genesis file with right denom
sed -i s%stake%$CONSUMER_DENOM%g $CONSUMER_HOME_1/config/genesis.json

# Set slashing to $DOWNTIME_BLOCKS
jq -r --arg SLASH "$DOWNTIME_BLOCKS" '.app_state.slashing.params.signed_blocks_window |= $SLASH' $CONSUMER_HOME_1/config/genesis.json > consumer-slashing.json
mv consumer-slashing.json $CONSUMER_HOME_1/config/genesis.json

# Create self-delegation accounts
echo $MNEMONIC_1 | $CONSUMER_CHAIN_BINARY keys add $MONIKER_1 --keyring-backend test --home $CONSUMER_HOME_1 --recover
echo $MNEMONIC_4 | $CONSUMER_CHAIN_BINARY keys add $MONIKER_4 --keyring-backend test --home $CONSUMER_HOME_1 --recover

# Add funds to accounts
if [ $CONSUMER_NEW ]
then
    echo "Running: $CONSUMER_CHAIN_BINARY genesis add-genesis-account $MONIKER_1 $VAL_FUNDS$CONSUMER_DENOM --home $CONSUMER_HOME_1"
    $CONSUMER_CHAIN_BINARY genesis add-genesis-account $MONIKER_1 $VAL_FUNDS$CONSUMER_DENOM --home $CONSUMER_HOME_1
    $CONSUMER_CHAIN_BINARY genesis add-genesis-account $MONIKER_4 $VAL_FUNDS$CONSUMER_DENOM --home $CONSUMER_HOME_1
else
    echo "Running: $CONSUMER_CHAIN_BINARY add-genesis-account $MONIKER_1 $VAL_FUNDS$CONSUMER_DENOM --home $CONSUMER_HOME_1"
    $CONSUMER_CHAIN_BINARY add-genesis-account $MONIKER_1 $VAL_FUNDS$CONSUMER_DENOM --home $CONSUMER_HOME_1
    $CONSUMER_CHAIN_BINARY add-genesis-account $MONIKER_4 $VAL_FUNDS$CONSUMER_DENOM --home $CONSUMER_HOME_1
fi

echo "Patching config files..."
# app.toml
# minimum_gas_prices
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"0$CONSUMER_DENOM\"^" $CONSUMER_HOME_1/config/app.toml

# Enable API
toml set --toml-path $CONSUMER_HOME_1/config/app.toml api.enable true

# Set different ports for api
toml set --toml-path $CONSUMER_HOME_1/config/app.toml api.address "tcp://0.0.0.0:$CON1_API_PORT"

# Set different ports for grpc
toml set --toml-path $CONSUMER_HOME_1/config/app.toml grpc.address "0.0.0.0:$CON1_GRPC_PORT"

# Turn off grpc web
toml set --toml-path $CONSUMER_HOME_1/config/app.toml grpc-web.enable false

# config.toml
# Set different ports for rpc
toml set --toml-path $CONSUMER_HOME_1/config/config.toml rpc.laddr "tcp://0.0.0.0:$CON1_RPC_PORT"

# Set different ports for rpc pprof
toml set --toml-path $CONSUMER_HOME_1/config/config.toml rpc.pprof_laddr "localhost:$CON1_PPROF_PORT"

# Set different ports for p2p
toml set --toml-path $CONSUMER_HOME_1/config/config.toml p2p.laddr "tcp://0.0.0.0:$CON1_P2P_PORT"

# Turn off block_sync
if [ $CONSUMER_NEW ]
then
    toml set --toml-path $CONSUMER_HOME_1/config/config.toml block_sync "false"
else
    toml set --toml-path $CONSUMER_HOME_1/config/config.toml fast_sync "false"
fi

# Allow duplicate IPs in p2p
toml set --toml-path $CONSUMER_HOME_1/config/config.toml p2p.allow_duplicate_ip true

echo "Setting up services..."
echo "Creating script for $CONSUMER_CHAIN_BINARY"
echo "while true; do $HOME/go/bin/$CONSUMER_CHAIN_BINARY start --home $CONSUMER_HOME_1; sleep 1; done" > $HOME/$CONSUMER_SERVICE_1.sh
chmod +x $HOME/$CONSUMER_SERVICE_1.sh

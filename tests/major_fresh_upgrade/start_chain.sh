#!/bin/bash
# 1. Set up a two-validator provider chain.

# Install Gaia binary
# CHAIN_BINARY_URL=https://github.com/cosmos/gaia/releases/download/$START_VERSION/gaiad-$START_VERSION-linux-amd64
echo "Installing Gaia..."
wget $CHAIN_BINARY_URL -O $HOME/go/bin/$CHAIN_BINARY -q
chmod +x $HOME/go/bin/$CHAIN_BINARY

# Printing Gaia binary checksum
echo GAIA_CHECKSUM: $(sha256sum $HOME/go/bin/$CHAIN_BINARY)

# Initialize home directories
echo "Initializing node homes..."
$CHAIN_BINARY config chain-id $CHAIN_ID --home $HOME_1
$CHAIN_BINARY config keyring-backend test --home $HOME_1
$CHAIN_BINARY config node tcp://localhost:$VAL1_RPC_PORT --home $HOME_1
$CHAIN_BINARY init $MONIKER_1 --chain-id $CHAIN_ID --home $HOME_1

$CHAIN_BINARY config chain-id $CHAIN_ID --home $HOME_2
$CHAIN_BINARY config keyring-backend test --home $HOME_2
$CHAIN_BINARY config node tcp://localhost:$VAL2_RPC_PORT --home $HOME_2
$CHAIN_BINARY init $MONIKER_2 --chain-id $CHAIN_ID --home $HOME_2

$CHAIN_BINARY config chain-id $CHAIN_ID --home $HOME_3
$CHAIN_BINARY config keyring-backend test --home $HOME_3
$CHAIN_BINARY config node tcp://localhost:$VAL3_RPC_PORT --home $HOME_3
$CHAIN_BINARY init $MONIKER_3 --chain-id $CHAIN_ID --home $HOME_3

# Create self-delegation accounts
echo $MNEMONIC_1 | $CHAIN_BINARY keys add $MONIKER_1 --keyring-backend test --home $HOME_1 --recover
echo $MNEMONIC_2 | $CHAIN_BINARY keys add $MONIKER_2 --keyring-backend test --home $HOME_1 --recover
echo $MNEMONIC_3 | $CHAIN_BINARY keys add $MONIKER_3 --keyring-backend test --home $HOME_1 --recover
echo $MNEMONIC_4 | $CHAIN_BINARY keys add $MONIKER_4 --keyring-backend test --home $HOME_1 --recover
echo $MNEMONIC_5 | $CHAIN_BINARY keys add $MONIKER_5 --keyring-backend test --home $HOME_1 --recover

# Update genesis file with right denom
echo "Setting denom to $DENOM..."
jq -r --arg denom "$DENOM" '.app_state.crisis.constant_fee.denom |= $denom' $HOME_1/config/genesis.json > crisis.json
jq -r --arg denom "$DENOM" '.app_state.gov.deposit_params.min_deposit[0].denom |= $denom' crisis.json > min_deposit.json
jq -r --arg denom "$DENOM" '.app_state.mint.params.mint_denom |= $denom' min_deposit.json > mint.json
jq -r --arg denom "$DENOM" '.app_state.staking.params.bond_denom |= $denom' mint.json > bond_denom.json
jq -r --arg denom "$DENOM" '.app_state.provider.params.consumer_reward_denom_registration_fee.denom = $denom' bond_denom.json > reward_reg.json
cp reward_reg.json $HOME_1/config/genesis.json

# Add funds to accounts
$CHAIN_BINARY add-genesis-account $MONIKER_1 $VAL_FUNDS$DENOM --home $HOME_1
$CHAIN_BINARY add-genesis-account $MONIKER_2 $VAL_FUNDS$DENOM --home $HOME_1
$CHAIN_BINARY add-genesis-account $MONIKER_3 $VAL_FUNDS$DENOM --home $HOME_1
$CHAIN_BINARY add-genesis-account $MONIKER_4 $VAL_FUNDS$DENOM --home $HOME_1
$CHAIN_BINARY add-genesis-account $MONIKER_5 $VAL_FUNDS$DENOM --home $HOME_1

echo "Creating and collecting gentxs..."
mkdir -p $HOME_1/config/gentx
VAL1_NODE_ID=$($CHAIN_BINARY tendermint show-node-id --home $HOME_1)
VAL2_NODE_ID=$($CHAIN_BINARY tendermint show-node-id --home $HOME_2)
VAL3_NODE_ID=$($CHAIN_BINARY tendermint show-node-id --home $HOME_3)
$CHAIN_BINARY gentx $MONIKER_1 $VAL1_STAKE$DENOM --pubkey "$($CHAIN_BINARY tendermint show-validator --home $HOME_1)" --node-id $VAL1_NODE_ID --moniker $MONIKER_1 --chain-id $CHAIN_ID --home $HOME_1 --output-document $HOME_1/config/gentx/$MONIKER_1-gentx.json
$CHAIN_BINARY gentx $MONIKER_2 $VAL2_STAKE$DENOM --pubkey "$($CHAIN_BINARY tendermint show-validator --home $HOME_2)" --node-id $VAL2_NODE_ID --moniker $MONIKER_2 --chain-id $CHAIN_ID --home $HOME_1 --output-document $HOME_1/config/gentx/$MONIKER_2-gentx.json
$CHAIN_BINARY gentx $MONIKER_3 $VAL3_STAKE$DENOM --pubkey "$($CHAIN_BINARY tendermint show-validator --home $HOME_3)" --node-id $VAL3_NODE_ID --moniker $MONIKER_3 --chain-id $CHAIN_ID --home $HOME_1 --output-document $HOME_1/config/gentx/$MONIKER_3-gentx.json
$CHAIN_BINARY collect-gentxs --home $HOME_1

echo "Patching genesis file for fast governance..."
jq -r ".app_state.gov.voting_params.voting_period = \"$VOTING_PERIOD\"" $HOME_1/config/genesis.json  > ./voting.json
jq -r ".app_state.gov.deposit_params.min_deposit[0].amount = \"1\"" ./voting.json > ./gov.json

echo "Setting slashing window to 10..."
jq -r --arg SLASH "10" '.app_state.slashing.params.signed_blocks_window |= $SLASH' ./gov.json > ./slashing.json
jq -r '.app_state.slashing.params.downtime_jail_duration |= "5s"' slashing.json > slashing-2.json
# mv slashing-2.json $HOME_1/config/genesis.json

# echo "Patching genesis file for LSM params..."
# jq -r '.app_state.staking.params.validator_bond_factor = "10.000000000000000000"' slashing-2.json > lsm-1.json
# jq -r '.app_state.staking.params.global_liquid_staking_cap = "0.100000000000000000"' lsm-1.json > lsm-2.json
# jq -r '.app_state.staking.params.validator_liquid_staking_cap = "0.200000000000000000"' lsm-2.json > lsm-3.json

echo "Patching genesis for ICA messages..."
# Gaia
jq -r '.app_state.interchainaccounts.host_genesis_state.params.allow_messages[0] = "*"' slashing-2.json > ./ica_host.json
mv ica_host.json $HOME_1/config/genesis.json
# pd

jq '.app_state.interchainaccounts' $HOME_1/config/genesis.json

echo "Copying genesis file to other nodes..."
cp $HOME_1/config/genesis.json $HOME_2/config/genesis.json 
cp $HOME_1/config/genesis.json $HOME_3/config/genesis.json 

echo "Patching config files..."
# app.toml
# minimum_gas_prices
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"$GAS_PRICE$DENOM\"^" $HOME_1/config/app.toml
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"$GAS_PRICE$DENOM\"^" $HOME_2/config/app.toml
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"$GAS_PRICE$DENOM\"^" $HOME_3/config/app.toml

# Enable API
toml set --toml-path $HOME_1/config/app.toml api.enable true
toml set --toml-path $HOME_2/config/app.toml api.enable true
toml set --toml-path $HOME_3/config/app.toml api.enable true

# Set different ports for api
toml set --toml-path $HOME_1/config/app.toml api.address "tcp://0.0.0.0:$VAL1_API_PORT"
toml set --toml-path $HOME_2/config/app.toml api.address "tcp://0.0.0.0:$VAL2_API_PORT"
toml set --toml-path $HOME_3/config/app.toml api.address "tcp://0.0.0.0:$VAL3_API_PORT"

# Set different ports for grpc
toml set --toml-path $HOME_1/config/app.toml grpc.address "0.0.0.0:$VAL1_GRPC_PORT"
toml set --toml-path $HOME_2/config/app.toml grpc.address "0.0.0.0:$VAL2_GRPC_PORT"
toml set --toml-path $HOME_3/config/app.toml grpc.address "0.0.0.0:$VAL3_GRPC_PORT"

# Turn off grpc web
toml set --toml-path $HOME_1/config/app.toml grpc-web.enable false
toml set --toml-path $HOME_2/config/app.toml grpc-web.enable false
toml set --toml-path $HOME_3/config/app.toml grpc-web.enable false

# config.toml
# Set log level to debug
# toml set --toml-path $HOME_1/config/config.toml log_level "debug"

# Set different ports for rpc
toml set --toml-path $HOME_1/config/config.toml rpc.laddr "tcp://0.0.0.0:$VAL1_RPC_PORT"
toml set --toml-path $HOME_2/config/config.toml rpc.laddr "tcp://0.0.0.0:$VAL2_RPC_PORT"
toml set --toml-path $HOME_3/config/config.toml rpc.laddr "tcp://0.0.0.0:$VAL3_RPC_PORT"

# Set different ports for rpc pprof
toml set --toml-path $HOME_1/config/config.toml rpc.pprof_laddr "localhost:$VAL1_PPROF_PORT"
toml set --toml-path $HOME_2/config/config.toml rpc.pprof_laddr "localhost:$VAL2_PPROF_PORT"
toml set --toml-path $HOME_3/config/config.toml rpc.pprof_laddr "localhost:$VAL3_PPROF_PORT"

# Set different ports for p2p
toml set --toml-path $HOME_1/config/config.toml p2p.laddr "tcp://0.0.0.0:$VAL1_P2P_PORT"
toml set --toml-path $HOME_2/config/config.toml p2p.laddr "tcp://0.0.0.0:$VAL2_P2P_PORT"
toml set --toml-path $HOME_3/config/config.toml p2p.laddr "tcp://0.0.0.0:$VAL3_P2P_PORT"

# Allow duplicate IPs in p2p
toml set --toml-path $HOME_1/config/config.toml p2p.allow_duplicate_ip true
toml set --toml-path $HOME_2/config/config.toml p2p.allow_duplicate_ip true
toml set --toml-path $HOME_3/config/config.toml p2p.allow_duplicate_ip true

echo "Setting a short commit timeout..."
seconds=s
toml set --toml-path $HOME_1/config/config.toml consensus.timeout_commit "$COMMIT_TIMEOUT$seconds"
toml set --toml-path $HOME_2/config/config.toml consensus.timeout_commit "$COMMIT_TIMEOUT$seconds"
toml set --toml-path $HOME_3/config/config.toml consensus.timeout_commit "$COMMIT_TIMEOUT$seconds"

# Set persistent peers
echo "Setting persistent peers..."
VAL2_PEER="$VAL2_NODE_ID@localhost:$VAL2_P2P_PORT"
VAL3_PEER="$VAL3_NODE_ID@localhost:$VAL3_P2P_PORT"
toml set --toml-path $HOME_1/config/config.toml p2p.persistent_peers "$VAL2_PEER,$VAL3_PEER"

toml set --toml-path $HOME_1/config/config.toml p2p.addr_book_strict false
toml set --toml-path $HOME_2/config/config.toml p2p.addr_book_strict false
toml set --toml-path $HOME_3/config/config.toml p2p.addr_book_strict false


# Set fast_sync to false
toml set --toml-path $HOME_1/config/config.toml block_sync false
toml set --toml-path $HOME_2/config/config.toml block_sync false
toml set --toml-path $HOME_3/config/config.toml block_sync false
toml set --toml-path $HOME_1/config/config.toml fast_sync false
toml set --toml-path $HOME_2/config/config.toml fast_sync false
toml set --toml-path $HOME_3/config/config.toml fast_sync false

echo "Setting up cosmovisor..."
if [ "$COSMOVISOR" = true ]; then
    mkdir -p $HOME_1/cosmovisor/genesis/bin
    mkdir -p $HOME_2/cosmovisor/genesis/bin
    mkdir -p $HOME_3/cosmovisor/genesis/bin
    cp $HOME/go/bin/$CHAIN_BINARY $HOME_1/cosmovisor/genesis/bin/
    cp $HOME/go/bin/$CHAIN_BINARY $HOME_2/cosmovisor/genesis/bin/
    cp $HOME/go/bin/$CHAIN_BINARY $HOME_3/cosmovisor/genesis/bin/
fi

echo "Setting up services..."

sudo touch /etc/systemd/system/$PROVIDER_SERVICE_1
echo "[Unit]"                               | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1
echo "Description=Gaia service"             | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo ""                                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "User=$USER"                           | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
if [ "$COSMOVISOR" = true ]; then
    echo "ExecStart=$HOME/go/bin/cosmovisor run start --x-crisis-skip-assert-invariants --home $HOME_1" | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
    echo "Environment=\"DAEMON_NAME=$CHAIN_BINARY\""               | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
    echo "Environment=\"DAEMON_HOME=$HOME_1\""                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
    echo "Environment=\"DAEMON_RESTART_AFTER_UPGRADE=true\""       | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
    echo "Environment=\"DAEMON_LOG_BUFFER_SIZE=512\""              | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
    if [ "$UPGRADE_MECHANISM" = 'cv_auto' ]; then
        echo "Environment=\"DAEMON_ALLOW_DOWNLOAD_BINARIES=true\"" | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
    fi
else
    echo "ExecStart=$HOME/go/bin/$CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $HOME_1" | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
fi
echo "Restart=no"                           | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo ""                                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_1 -a

sudo touch /etc/systemd/system/$PROVIDER_SERVICE_2
echo "[Unit]"                               | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2
echo "Description=Gaia service"             | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo ""                                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "User=$USER"                           | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
if [ "$COSMOVISOR" = true ]; then
    echo "ExecStart=$HOME/go/bin/cosmovisor run start --x-crisis-skip-assert-invariants --home $HOME_2" | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
    echo "Environment=\"DAEMON_NAME=$CHAIN_BINARY\""               | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
    echo "Environment=\"DAEMON_HOME=$HOME_2\""                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
    echo "Environment=\"DAEMON_RESTART_AFTER_UPGRADE=true\""       | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
    echo "Environment=\"DAEMON_LOG_BUFFER_SIZE=512\""              | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
    if [ "$UPGRADE_MECHANISM" = 'cv_auto' ]; then
        echo "Environment=\"DAEMON_ALLOW_DOWNLOAD_BINARIES=true\"" | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
    fi
else
    echo "ExecStart=$HOME/go/bin/$CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $HOME_2" | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
fi
echo "Restart=no"                           | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a

echo ""                                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a

sudo touch /etc/systemd/system/$PROVIDER_SERVICE_3
echo "[Unit]"                               | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3
echo "Description=Gaia service"             | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
echo ""                                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
echo "User=$USER"                           | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
if [ "$COSMOVISOR" = true ]; then
    echo "ExecStart=$HOME/go/bin/cosmovisor run start --x-crisis-skip-assert-invariants --home $HOME_3" | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
    echo "Environment=\"DAEMON_NAME=$CHAIN_BINARY\""               | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
    echo "Environment=\"DAEMON_HOME=$HOME_3\""                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
    echo "Environment=\"DAEMON_RESTART_AFTER_UPGRADE=true\""       | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
    echo "Environment=\"DAEMON_LOG_BUFFER_SIZE=512\""              | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
    if [ "$UPGRADE_MECHANISM" = 'cv_auto' ]; then
        echo "Environment=\"DAEMON_ALLOW_DOWNLOAD_BINARIES=true\"" | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
    fi
else
    echo "ExecStart=$HOME/go/bin/$CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $HOME_3" | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
fi
echo "Restart=no"                           | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a

echo ""                                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_3 -a

sudo cat /etc/systemd/system/$PROVIDER_SERVICE_1

sudo systemctl daemon-reload
sudo systemctl enable $PROVIDER_SERVICE_1 --now
sudo systemctl enable $PROVIDER_SERVICE_2 --now
sudo systemctl enable $PROVIDER_SERVICE_3 --now

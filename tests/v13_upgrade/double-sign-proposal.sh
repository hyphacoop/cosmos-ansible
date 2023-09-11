#!/bin/bash
# Test equivocation proposal for double-signing

source tests/process_tx.sh

echo "Setting up provider node..."
$CHAIN_BINARY config chain-id $CHAIN_ID --home $EQ1_HOME_PROVIDER
$CHAIN_BINARY config keyring-backend test --home $EQ1_HOME_PROVIDER
$CHAIN_BINARY config broadcast-mode block --home $EQ1_HOME_PROVIDER
$CHAIN_BINARY config node tcp://localhost:$VAL_EQ1_RPC_PORT --home $EQ1_HOME_PROVIDER
$CHAIN_BINARY init malval_1 --chain-id $CHAIN_ID --home $EQ1_HOME_PROVIDER

echo "Getting genesis file..."
cp $HOME_1/config/genesis.json $EQ1_HOME_PROVIDER/config/genesis.json

echo "Patching config files..."
# app.toml
# minimum_gas_prices
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"0.0025$DENOM\"^" $EQ1_HOME_PROVIDER/config/app.toml
# Enable API
toml set --toml-path $EQ1_HOME_PROVIDER/config/app.toml api.enable true
# Set different ports for api
toml set --toml-path $EQ1_HOME_PROVIDER/config/app.toml api.address "tcp://0.0.0.0:$VAL_EQ1_API_PORT"
# Set different ports for grpc
toml set --toml-path $EQ1_HOME_PROVIDER/config/app.toml grpc.address "0.0.0.0:$VAL_EQ1_GRPC_PORT"
# Turn off grpc web
toml set --toml-path $EQ1_HOME_PROVIDER/config/app.toml grpc-web.enable false
# config.toml
# Set different ports for rpc
toml set --toml-path $EQ1_HOME_PROVIDER/config/config.toml rpc.laddr "tcp://0.0.0.0:$VAL_EQ1_RPC_PORT"
# Set different ports for rpc pprof
toml set --toml-path $EQ1_HOME_PROVIDER/config/config.toml rpc.pprof_laddr "localhost:$VAL_EQ1_PPROF_PORT"
# Set different ports for p2p
toml set --toml-path $EQ1_HOME_PROVIDER/config/config.toml p2p.laddr "tcp://0.0.0.0:$VAL_EQ1_P2P_PORT"
# Allow duplicate IPs in p2p
toml set --toml-path $EQ1_HOME_PROVIDER/config/config.toml p2p.allow_duplicate_ip true
echo "Setting a short commit timeout..."
seconds=s
toml set --toml-path $EQ1_HOME_PROVIDER/config/config.toml consensus.timeout_commit "$COMMIT_TIMEOUT$seconds"
# Set persistent peers
echo "Setting persistent peers..."
VAL2_NODE_ID=$($CHAIN_BINARY tendermint show-node-id --home $HOME_2)
VAL3_NODE_ID=$($CHAIN_BINARY tendermint show-node-id --home $HOME_3)
VAL2_PEER="$VAL2_NODE_ID@localhost:$VAL2_P2P_PORT"
VAL3_PEER="$VAL3_NODE_ID@localhost:$VAL3_P2P_PORT"
toml set --toml-path $EQ1_HOME_PROVIDER/config/config.toml p2p.persistent_peers "$VAL2_PEER,$VAL3_PEER"
# Set fast_sync to false
toml set --toml-path $EQ1_HOME_PROVIDER/config/config.toml fast_sync false

echo "Setting up service..."

sudo touch /etc/systemd/system/$VAL_EQ1_SERVICE
echo "[Unit]"                               | sudo tee /etc/systemd/system/$VAL_EQ1_SERVICE
echo "Description=Gaia service"             | sudo tee /etc/systemd/system/$VAL_EQ1_SERVICE -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$VAL_EQ1_SERVICE -a
echo ""                                     | sudo tee /etc/systemd/system/$VAL_EQ1_SERVICE -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$VAL_EQ1_SERVICE -a
echo "User=$USER"                           | sudo tee /etc/systemd/system/$VAL_EQ1_SERVICE -a
echo "ExecStart=$HOME/go/bin/$CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $EQ1_HOME_PROVIDER" | sudo tee /etc/systemd/system/$VAL_EQ1_SERVICE -a
echo "Restart=no"                           | sudo tee /etc/systemd/system/$VAL_EQ1_SERVICE -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$VAL_EQ1_SERVICE -a
echo ""                                     | sudo tee /etc/systemd/system/$VAL_EQ1_SERVICE -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$VAL_EQ1_SERVICE -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$VAL_EQ1_SERVICE -a

echo "Starting provider service..."
sudo systemctl enable $VAL_EQ1_SERVICE --now

sleep 20
$CHAIN_BINARY q block --home $EQ1_HOME_PROVIDER | jq '.'
curl http://localhost:$VAL_EQ1_RPC_PORT/status | jq -r '.result.sync_info'

echo "Setting up consumer node..."
$CONSUMER_CHAIN_BINARY config chain-id $CONSUMER_CHAIN_ID --home $EQ1_HOME_CONSUMER
$CONSUMER_CHAIN_BINARY config keyring-backend test --home $EQ1_HOME_CONSUMER
$CONSUMER_CHAIN_BINARY config node tcp://localhost:$CON_EQ1_RPC_PORT --home $EQ1_HOME_CONSUMER
$CONSUMER_CHAIN_BINARY init malval_1 --chain-id $CONSUMER_CHAIN_ID --home $EQ1_HOME_CONSUMER

echo "Copying key from provider node to consumer one..."
cp $EQ1_HOME_PROVIDER/config/priv_validator_key.json $EQ1_HOME_CONSUMER/config/priv_validator_key.json
cp $EQ1_HOME_PROVIDER/config/node_key.json $EQ1_HOME_CONSUMER/config/node_key.json

echo "Getting patched genesis file..."
cp $CONSUMER_HOME_1/config/genesis.json $EQ1_HOME_CONSUMER/config/genesis.json

echo "Patching config files..."
# app.toml
# minimum_gas_prices
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"0$CONSUMER_DENOM\"^" $EQ1_HOME_CONSUMER/config/app.toml
# Enable API
toml set --toml-path $EQ1_HOME_CONSUMER/config/app.toml api.enable true
# Set different ports for api
toml set --toml-path $EQ1_HOME_CONSUMER/config/app.toml api.address "tcp://0.0.0.0:$CON_EQ1_API_PORT"
# Set different ports for grpc
toml set --toml-path $EQ1_HOME_CONSUMER/config/app.toml grpc.address "0.0.0.0:$CON_EQ1_GRPC_PORT"
# Turn off grpc web
toml set --toml-path $EQ1_HOME_CONSUMER/config/app.toml grpc-web.enable false
# config.toml
# Set different ports for rpc
toml set --toml-path $EQ1_HOME_CONSUMER/config/config.toml rpc.laddr "tcp://0.0.0.0:$CON_EQ1_RPC_PORT"
# Set different ports for rpc pprof
toml set --toml-path $EQ1_HOME_CONSUMER/config/config.toml rpc.pprof_laddr "localhost:$CON_EQ1_PPROF_PORT"
# Set different ports for p2p
toml set --toml-path $EQ1_HOME_CONSUMER/config/config.toml p2p.laddr "tcp://0.0.0.0:$CON_EQ1_P2P_PORT"
# Allow duplicate IPs in p2p
toml set --toml-path $EQ1_HOME_CONSUMER/config/config.toml p2p.allow_duplicate_ip true
echo "Setting persistent peer..."
CON1_NODE_ID=$($CONSUMER_CHAIN_BINARY tendermint show-node-id --home $CONSUMER_HOME_1)
CON1_PEER="$CON1_NODE_ID@localhost:$CON1_P2P_PORT"
toml set --toml-path $EQ1_HOME_CONSUMER/config/config.toml p2p.persistent_peers "$CON1_PEER"
echo "Setting a short commit timeout..."
toml set --toml-path $EQ1_HOME_CONSUMER/config/config.toml consensus.timeout_commit "1s"
# Set fast_sync to false - or block_sync for ICS v3
toml set --toml-path $EQ1_HOME_CONSUMER/config/config.toml fast_sync false
toml set --toml-path $EQ1_HOME_CONSUMER/config/config.toml block_sync false

echo "Setting up services..."

sudo touch /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL
echo "[Unit]"                               | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL
echo "Description=Consumer service"       | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL -a
echo ""                                     | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL -a
echo "ExecStart=$HOME/go/bin/$CONSUMER_CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $EQ1_HOME_CONSUMER" | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL -a
echo "Restart=no"                       | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL -a
echo ""                                     | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_ORIGINAL -a

sudo touch /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE
echo "[Unit]"                               | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE
echo "Description=Consumer service"       | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE -a
echo ""                                     | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE -a
echo "ExecStart=$HOME/go/bin/$CONSUMER_CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $EQ1_HOME_CONSUMER_DOUBLE" | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE -a
echo "Restart=no"                       | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE -a
echo ""                                     | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$CON_EQ1_SERVICE_DOUBLE -a

echo "Starting consumer service..."
sudo systemctl enable $CON_EQ1_SERVICE_ORIGINAL --now

sleep 20
$CONSUMER_CHAIN_BINARY q block --home $EQ1_HOME_CONSUMER | jq '.'

echo "Create new validator key..."
$CHAIN_BINARY keys add malval_1 --home $EQ1_HOME_PROVIDER
malval_1=$($CHAIN_BINARY keys list --home $EQ1_HOME_PROVIDER --output json | jq -r '.[] | select(.name=="malval_1").address')

echo "Fund new validator..."
submit_tx "tx bank send $WALLET_1 $malval_1 100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1

echo "Create validator..."
# submit_tx "tx staking create-validator --amount 1000000uatom --pubkey $($CHAIN_BINARY tendermint show-validator --home $EQ1_HOME_PROVIDER) --moniker malval_1 --chain-id $CHAIN_ID --commission-rate 0.10 --commission-max-rate 0.20 --commission-max-change-rate 0.01 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees 1000$DENOM --from $malval_1" $CHAIN_BINARY $EQ1_HOME_PROVIDER
$CHAIN_BINARY tx staking create-validator --amount 10000000$DENOM \
--pubkey $($CHAIN_BINARY tendermint show-validator --home $EQ1_HOME_PROVIDER) \
--moniker malval_1 --chain-id $CHAIN_ID \
--commission-rate 0.10 --commission-max-rate 0.20 --commission-max-change-rate 0.01 \
--gas auto --gas-adjustment $GAS_ADJUSTMENT --fees 2000$DENOM --from $malval_1 --home $EQ1_HOME_PROVIDER -b block -y

sleep 10

echo "Check validator is in the consumer chain..."
$CONSUMER_CHAIN_BINARY q tendermint-validator-set --home $CONSUMER_HOME_1

# # Stop validator

# # Duplicate home folder

# # Start duplicate

# # Start original

# # Wait for original
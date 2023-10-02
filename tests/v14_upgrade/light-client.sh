#!/bin/bash

# Validators 1 and 2 will fork the chain

echo "0. Get trusted height"
TRUSTED_HEIGHT=$(hermes --json --config ~/.hermes/config.toml query client consensus --chain $CHAIN_ID --client 07-tendermint-0 | tail -n 1 | jq '.result[2].revision_height')
echo "Trusted height: $TRUSTED_HEIGHT"

echo "1. Stop $CONSUMER_SERVICE_1 and $CONSUMER_SERVICE_2..."
systemctl stop $CONSUMER_SERVICE_1
systemctl stop $CONSUMER_SERVICE_2

echo "2. Duplicate validator home folder..."
cp -r $CONSUMER_HOME_1 $CONSUMER_HOME_1F
cp -r $CONSUMER_HOME_2 $CONSUMER_HOME_2F

echo "Start $CONSUMER_SERVICE_1 AND $CONSUMER_SERVICE_2 again..."
systemctl start $CONSUMER_SERVICE_1
systemctl start $CONSUMER_SERVICE_2
sleep 10

echo "3. Clear persistent peers..."
CON2_NODE_ID=$($CONSUMER_CHAIN_BINARY tendermint show-node-id --home $CONSUMER_HOME_2F)
CON2_PEER="$CON2_NODE_ID@127.0.0.1:$CON2F_P2P_PORT"
toml set --toml-path $CONSUMER_HOME_1F/config/config.toml p2p.persistent_peers "$CON2_PEER"
toml set --toml-path $CONSUMER_HOME_2F/config/config.toml p2p.persistent_peers ""

echo "4. Update ports..."
toml set --toml-path $CONSUMER_HOME_1F/config/app.toml api.address "tcp://0.0.0.0:$CON1F_API_PORT"
toml set --toml-path $CONSUMER_HOME_2F/config/app.toml api.address "tcp://0.0.0.0:$CON2F_API_PORT"
toml set --toml-path $CONSUMER_HOME_1F/config/app.toml grpc.address "0.0.0.0:$CON1F_GRPC_PORT"
toml set --toml-path $CONSUMER_HOME_2F/config/app.toml grpc.address "0.0.0.0:$CON2F_GRPC_PORT"
toml set --toml-path $CONSUMER_HOME_1F/config/config.toml rpc.laddr "tcp://0.0.0.0:$CON1F_RPC_PORT"
toml set --toml-path $CONSUMER_HOME_2F/config/config.toml rpc.laddr "tcp://0.0.0.0:$CON2F_RPC_PORT"
toml set --toml-path $CONSUMER_HOME_1F/config/config.toml rpc.pprof_laddr "127.0.0.1:$CON1F_PPROF_PORT"
toml set --toml-path $CONSUMER_HOME_2F/config/config.toml rpc.pprof_laddr "127.0.0.1:$CON2F_PPROF_PORT"
toml set --toml-path $CONSUMER_HOME_1F/config/config.toml p2p.laddr "tcp://0.0.0.0:$CON1F_P2P_PORT"
toml set --toml-path $CONSUMER_HOME_2F/config/config.toml p2p.laddr "tcp://0.0.0.0:$CON2F_P2P_PORT"

echo "5. Wipe the address book..."
echo "{}" > $CONSUMER_HOME_1F/config/addrbook.json
echo "{}" > $CONSUMER_HOME_2F/config/addrbook.json

echo "6. Start fork."
systemctl start $CONSUMER_SERVICE_1F
systemctl start $CONSUMER_SERVICE_2F
sleep 5

echo "7. Update the light client of the consumer chain fork on the provider"
hermes --config ~/.hermes/config-2.toml update client --client 07-tendermint-0 --host-chain provider --trusted-height $TRUSTED_HEIGHT

echo "Waiting for evidence to be sent to provider..."
sleep 60

journalctl -u hermes | tail -n 20

journalctl -u $CONSUMER_SERVICE_1 | tail -n 10
journalctl -u $CONSUMER_SERVICE_1 | tail -n 10

$CHAIN_BINARY q slashing signing-infos --home $HOME_1
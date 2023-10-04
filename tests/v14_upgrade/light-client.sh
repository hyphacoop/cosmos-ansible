#!/bin/bash

# Validators 1 and 2 will fork the chain

echo "0. Get trusted height"
TRUSTED_HEIGHT=$(hermes --json --config ~/.hermes/config.toml query client consensus --chain $CHAIN_ID --client 07-tendermint-0 | tail -n 1 | jq '.result[2].revision_height')
echo "Trusted height: $TRUSTED_HEIGHT"

echo "1. Stop $CONSUMER_SERVICE_1 and $CONSUMER_SERVICE_2..."
sudo systemctl stop $CONSUMER_SERVICE_1
sudo systemctl stop $CONSUMER_SERVICE_2

echo "2. Duplicate validator home folders..."
cp -r $CONSUMER_HOME_1 $CONSUMER_HOME_1F
cp -r $CONSUMER_HOME_2 $CONSUMER_HOME_2F

echo "Start $CONSUMER_SERVICE_1 and $CONSUMER_SERVICE_2 again..."
sudo systemctl start $CONSUMER_SERVICE_1
sudo systemctl start $CONSUMER_SERVICE_2
sleep 15

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

echo "6. Set up fork services..."

sudo touch /etc/systemd/system/$CONSUMER_SERVICE_1F
echo "[Unit]"                               | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1F
echo "Description=Consumer service"         | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1F -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1F -a
echo ""                                     | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1F -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1F -a
echo "User=$USER"                           | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1F -a
echo "ExecStart=$HOME/go/bin/$CONSUMER_CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $CONSUMER_HOME_1F" | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1F -a
echo "Restart=no"                           | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1F -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1F -a
echo ""                                     | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1F -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1F -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_1F -a

sudo touch /etc/systemd/system/$CONSUMER_SERVICE_2F
echo "[Unit]"                               | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2F
echo "Description=Consumer service"         | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2F -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2F -a
echo ""                                     | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2F -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2F -a
echo "User=$USER"                           | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2F -a
echo "ExecStart=$HOME/go/bin/$CONSUMER_CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $CONSUMER_HOME_2F" | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2F -a
echo "Restart=no"                           | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2F -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2F -a
echo ""                                     | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2F -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2F -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$CONSUMER_SERVICE_2F -a

sudo systemctl enable $CONSUMER_SERVICE_1F --now
sudo systemctl enable $CONSUMER_SERVICE_2F --now
sleep 30

echo "7. Update the light client of the consumer chain fork on the provider chain"
hermes --config ~/.hermes/config-2.toml update client --client 07-tendermint-0 --host-chain $CHAIN_ID --trusted-height $TRUSTED_HEIGHT

echo "Waiting for evidence to be sent to provider chain..."
sleep 30
sudo systemctl restart hermes
sleep 30

echo "Hermes:"
journalctl -u hermes | tail -n 100
echo "consumer 1:"
journalctl -u $CONSUMER_SERVICE_1 | tail -n 10
echo "consumer 1f:"
journalctl -u $CONSUMER_SERVICE_1F | tail -n 10
echo "validator 1:"
journalctl -u $PROVIDER_SERVICE_1 | tail -n 10

$CHAIN_BINARY q ibc client status 07-tendermint-0 --home $HOME_1
$CHAIN_BINARY q ibc client state 07-tendermint-0 -o json --home $HOME_1 | jq -r '.client_state.frozen_height'

$CHAIN_BINARY q slashing signing-infos --home $HOME_1

$CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1
jailed=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.jailed')
if [ $jailed != true ]; then
  echo "Equivocation detection failure: validator $VALOPER_1 was not jailed."
  exit 1
else
  echo "Equivocation detection success: validator $VALOPER_1 was jailed."
fi

$CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1
jailed=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.jailed')
if [ $jailed != true ]; then
  echo "Equivocation detection failure: validator $VALOPER_2 was not jailed."
  exit 1
else
  echo "Equivocation detection success: validator $VALOPER_2 was jailed."
fi
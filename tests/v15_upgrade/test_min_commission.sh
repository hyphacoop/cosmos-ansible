#!/bin/bash

# Try creating a validator with a minimum commision of less than 5% before and after the upgrade

if $UPGRADED_V15 ; then
    echo "Validator cannot be created with a minimum commission of less than the set by the param (5% for v15)"
    $CHAIN_BINARY q staking validators --home $MCVAL_HOME -o json | jq '.'
else
    echo "Validator can be created with a commission of 0%"
    MCVAL_HOME=/home/runner/.mcval1
    MCVAL_SERVICE=mcval1.service

    $CHAIN_BINARY keys add mc_val1 --home $HOME_1
    mc_val=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="mc_val1").address')
    $CHAIN_BINARY tx bank send $WALLET_1 $mc_val 10000000$DENOM --home $HOME_1 --from $WALLET_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
    sudo systemctl stop $PROVIDER_SERVICE_1
    cp -r $HOME_1 $MCVAL_HOME
    sudo systemctl start $PROVIDER_SERVICE_1
    $CHAIN_BINARY init dummy --home /home/runner/.dummykeys
    cp /home/runner/.dummykeys/config/priv_validator_key.json $MCVAL_HOME/config/priv_validator_key.json
    cp /home/runner/.dummykeys/config/node_key.json $MCVAL_HOME/config/node_key.json
    $CHAIN_BINARY tendermint unsafe-reset-all --home $MCVAL_HOME
    toml set --toml-path $MCVAL_HOME/config/app.toml api.address "tcp://0.0.0.0:25111"
    toml set --toml-path $MCVAL_HOME/config/app.toml grpc.address "0.0.0.0:26111"
    toml set --toml-path $MCVAL_HOME/config/config.toml rpc.laddr "tcp://0.0.0.0:27111"
    toml set --toml-path $MCVAL_HOME/config/config.toml rpc.pprof_laddr "localhost:29111"
    toml set --toml-path $MCVAL_HOME/config/config.toml p2p.laddr "tcp://0.0.0.0:28111"
    # $CHAIN_BINARY start --home $MCVAL_HOME

    sudo touch /etc/systemd/system/$MCVAL_SERVICE
    echo "[Unit]"                               | sudo tee /etc/systemd/system/$MCVAL_SERVICE
    echo "Description=Gaia service"             | sudo tee /etc/systemd/system/$MCVAL_SERVICE -a
    echo "After=network-online.target"          | sudo tee /etc/systemd/system/$MCVAL_SERVICE -a
    echo ""                                     | sudo tee /etc/systemd/system/$MCVAL_SERVICE -a
    echo "[Service]"                            | sudo tee /etc/systemd/system/$MCVAL_SERVICE -a
    echo "User=$USER"                           | sudo tee /etc/systemd/system/$MCVAL_SERVICE -a
    echo "ExecStart=$HOME/go/bin/$CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $MCVAL_HOME" | sudo tee /etc/systemd/system/$MCVAL_SERVICE -a
    echo "Restart=no"                           | sudo tee /etc/systemd/system/$MCVAL_SERVICE -a
    echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$MCVAL_SERVICE -a
    echo ""                                     | sudo tee /etc/systemd/system/$MCVAL_SERVICE -a
    echo "[Install]"                            | sudo tee /etc/systemd/system/$MCVAL_SERVICE -a
    echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$MCVAL_SERVICE -a
    sudo systemctl daemon-reload
    sudo systemctl enable $MCVAL_SERVICE
    sudo systemctl start $MCVAL_SERVICE
    sleep 20
    journalctl -u $MCVAL_SERVICE | tail

    $CHAIN_BINARY \
    tx staking create-validator \
    --amount 1000000$DENOM \
    --pubkey $($CHAIN_BINARY tendermint show-validator --home $MCVAL_HOME) \
    --moniker "mc_val1" \
    --chain-id $CHAIN_ID \
    --commission-rate "0.0" \
    --commission-max-rate "0.20" \
    --commission-max-change-rate "0.01" \
    --gas $GAS \
    --gas-adjustment $GAS_ADJUSTMENT \
    --gas-prices $GAS_PRICE$DENOM \
    --from $mc_val \
    --home $MCVAL_HOME \
    -y

    sleep $(( $COMMIT_TIMEOUT*2 ))

    $CHAIN_BINARY q staking validators --home $MCVAL_HOME -o json | jq '.'
    $CHAIN_BINARY keys parse $mc_val --output json | jq '.'

fi

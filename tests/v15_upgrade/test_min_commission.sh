#!/bin/bash

# Try creating a validator with a minimum commision of less than 5% before and after the upgrade
MCVAL_HOME_1=/home/runner/.mcval1
MCVAL_HOME_2=/home/runner/.mcval2
MCVAL_SERVICE_1=mcval1.service
MCVAL_SERVICE_2=mcval2.service

if $UPGRADED_V15 ; then
    echo "Validator with a min commission of <5% prior to the upgrade no has a 5% min commission"
    $CHAIN_BINARY keys list --home $MCVAL_HOME_1 --output json
    mc_val1=$($CHAIN_BINARY keys list --home $MCVAL_HOME_1 --output json | jq -r '.[] | select(.name=="mc_val1").address')
    echo "mcval1 address: $mc_val1"
    bytes_address=$($CHAIN_BINARY keys parse $mc_val1 --output json | jq -r '.bytes')
    echo "Bytes address: $bytes_address"
    cosmosvaloper=$($CHAIN_BINARY keys parse $bytes_address --output json | jq -r '.formats[2]')
    $CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r '.validators[].commission.commission_rates.rate'
    mcval1_commission=$($CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r --arg ADDR "$cosmosvaloper" '.validators[] | select(.operator_address==$ADDR).commission.commission_rates.rate')
    echo "mcval1_commission = $mcval1_commission"
    
    echo "Validator cannot be created with a minimum commission of less than the set by the param (5% for v15)"

    $CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq '.'
    $CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r '.validators[].commission.commission_rates.rate'

    sudo systemctl stop $PROVIDER_SERVICE_1
    cp -r $HOME_1 $MCVAL_HOME_2
    sudo systemctl start $PROVIDER_SERVICE_1
    $CHAIN_BINARY init dummy --home /home/runner/.dummykeys
    cp /home/runner/.dummykeys/config/priv_validator_key.json $MCVAL_HOME_2/config/priv_validator_key.json
    cp /home/runner/.dummykeys/config/node_key.json $MCVAL_HOME_2/config/node_key.json
    rm -rf /home/runner/.dummykeys
    $CHAIN_BINARY tendermint unsafe-reset-all --home $MCVAL_HOME_2
    toml set --toml-path $MCVAL_HOME_2/config/app.toml api.address "tcp://0.0.0.0:25112"
    toml set --toml-path $MCVAL_HOME_2/config/app.toml grpc.address "0.0.0.0:26112"
    toml set --toml-path $MCVAL_HOME_2/config/config.toml rpc.laddr "tcp://0.0.0.0:27112"
    toml set --toml-path $MCVAL_HOME_2/config/config.toml rpc.pprof_laddr "localhost:29112"
    toml set --toml-path $MCVAL_HOME_2/config/config.toml p2p.laddr "tcp://0.0.0.0:28112"

    $CHAIN_BINARY keys add mc_val2 --home $MCVAL_HOME_2
    mc_val2=$($CHAIN_BINARY keys list --home $MCVAL_HOME_2 --output json | jq -r '.[] | select(.name=="mc_val2").address')
    
    sudo touch /etc/systemd/system/$MCVAL_SERVICE_2
    echo "[Unit]"                               | sudo tee /etc/systemd/system/$MCVAL_SERVICE_2
    echo "Description=Gaia service"             | sudo tee /etc/systemd/system/$MCVAL_SERVICE_2 -a
    echo "After=network-online.target"          | sudo tee /etc/systemd/system/$MCVAL_SERVICE_2 -a
    echo ""                                     | sudo tee /etc/systemd/system/$MCVAL_SERVICE_2 -a
    echo "[Service]"                            | sudo tee /etc/systemd/system/$MCVAL_SERVICE_2 -a
    echo "User=$USER"                           | sudo tee /etc/systemd/system/$MCVAL_SERVICE_2 -a
    echo "ExecStart=$HOME/go/bin/$CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $MCVAL_HOME_2" | sudo tee /etc/systemd/system/$MCVAL_SERVICE_2 -a
    echo "Restart=no"                           | sudo tee /etc/systemd/system/$MCVAL_SERVICE_2 -a
    echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$MCVAL_SERVICE_2 -a
    echo ""                                     | sudo tee /etc/systemd/system/$MCVAL_SERVICE_2 -a
    echo "[Install]"                            | sudo tee /etc/systemd/system/$MCVAL_SERVICE_2 -a
    echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$MCVAL_SERVICE_2 -a
    sudo systemctl daemon-reload
    sudo systemctl enable $MCVAL_SERVICE_2
    sudo systemctl start $MCVAL_SERVICE_2
    sleep 20

    journalctl -u $MCVAL_SERVICE_2 | tail

else
    echo "Validator can be created with a commission of 0%"
    
    sudo systemctl stop $PROVIDER_SERVICE_1
    cp -r $HOME_1 $MCVAL_HOME_1
    sudo systemctl start $PROVIDER_SERVICE_1
    $CHAIN_BINARY init dummy --home /home/runner/.dummykeys
    cp /home/runner/.dummykeys/config/priv_validator_key.json $MCVAL_HOME_1/config/priv_validator_key.json
    cp /home/runner/.dummykeys/config/node_key.json $MCVAL_HOME_1/config/node_key.json
    rm -rf /home/runner/.dummykeys
    $CHAIN_BINARY tendermint unsafe-reset-all --home $MCVAL_HOME_1
    toml set --toml-path $MCVAL_HOME_1/config/app.toml api.address "tcp://0.0.0.0:25111"
    toml set --toml-path $MCVAL_HOME_1/config/app.toml grpc.address "0.0.0.0:26111"
    toml set --toml-path $MCVAL_HOME_1/config/config.toml rpc.laddr "tcp://0.0.0.0:27111"
    toml set --toml-path $MCVAL_HOME_1/config/config.toml rpc.pprof_laddr "localhost:29111"
    toml set --toml-path $MCVAL_HOME_1/config/config.toml p2p.laddr "tcp://0.0.0.0:28111"

    $CHAIN_BINARY keys add mc_val1 --home $MCVAL_HOME_1
    mc_val1=$($CHAIN_BINARY keys list --home $MCVAL_HOME_1 --output json | jq -r '.[] | select(.name=="mc_val1").address')
    
    sudo touch /etc/systemd/system/$MCVAL_SERVICE_1
    echo "[Unit]"                               | sudo tee /etc/systemd/system/$MCVAL_SERVICE_1
    echo "Description=Gaia service"             | sudo tee /etc/systemd/system/$MCVAL_SERVICE_1 -a
    echo "After=network-online.target"          | sudo tee /etc/systemd/system/$MCVAL_SERVICE_1 -a
    echo ""                                     | sudo tee /etc/systemd/system/$MCVAL_SERVICE_1 -a
    echo "[Service]"                            | sudo tee /etc/systemd/system/$MCVAL_SERVICE_1 -a
    echo "User=$USER"                           | sudo tee /etc/systemd/system/$MCVAL_SERVICE_1 -a
    echo "ExecStart=$HOME/go/bin/$CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $MCVAL_HOME_1" | sudo tee /etc/systemd/system/$MCVAL_SERVICE_1 -a
    echo "Restart=no"                           | sudo tee /etc/systemd/system/$MCVAL_SERVICE_1 -a
    echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$MCVAL_SERVICE_1 -a
    echo ""                                     | sudo tee /etc/systemd/system/$MCVAL_SERVICE_1 -a
    echo "[Install]"                            | sudo tee /etc/systemd/system/$MCVAL_SERVICE_1 -a
    echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$MCVAL_SERVICE_1 -a
    sudo systemctl daemon-reload
    sudo systemctl enable $MCVAL_SERVICE_1
    sudo systemctl start $MCVAL_SERVICE_1
    sleep 20

    journalctl -u $MCVAL_SERVICE_1 | tail

    $CHAIN_BINARY tx bank send $WALLET_1 $mc_val1 10000000$DENOM --home $HOME_1 --from $WALLET_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
    sleep $(( $COMMIT_TIMEOUT*2 ))
    $CHAIN_BINARY \
    tx staking create-validator \
    --amount 1000000$DENOM \
    --pubkey $($CHAIN_BINARY tendermint show-validator --home $MCVAL_HOME_1) \
    --moniker "mc_val1" \
    --chain-id $CHAIN_ID \
    --commission-rate "0.0" \
    --commission-max-rate "0.20" \
    --commission-max-change-rate "0.01" \
    --gas $GAS \
    --gas-adjustment $GAS_ADJUSTMENT \
    --gas-prices $GAS_PRICE$DENOM \
    --from $mc_val1 \
    --home $MCVAL_HOME_1 \
    -y

    sleep $(( $COMMIT_TIMEOUT*2 ))

    # $CHAIN_BINARY q staking validators --home $MCVAL_HOME_1 -o json | jq '.'
    bytes_address=$($CHAIN_BINARY keys parse $mc_val1 --output json | jq -r '.bytes')
    echo "Bytes address: $bytes_address"
    cosmosvaloper=$($CHAIN_BINARY keys parse $bytes_address --output json | jq -r '.formats[2]')
    # $CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r '.validators[].commission.commission_rates.rate'
    mcval1_commission=$($CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r --arg ADDR "$cosmosvaloper" '.validators[] | select(.operator_address==$ADDR).commission.commission_rates.rate')
    echo "mcval1_commission = $mcval1_commission"
    # commission=$($CHAIN_BINARY q staking validators --home $MCVAL_HOME_1 -o json | jq '.')
fi

#!/bin/bash
# Set up a relayer

if [ $RELAYER == "hermes" ]; then

    echo "Downloading Hermes..."
    wget https://github.com/informalsystems/hermes/releases/download/$HERMES_VERSION/hermes-$HERMES_VERSION-x86_64-unknown-linux-gnu.tar.gz -O hermes-$HERMES_VERSION.tar.gz
    tar -xzvf hermes-$HERMES_VERSION.tar.gz
    mkdir -p ~/.hermes
    cp hermes ~/.hermes/hermes
    export PATH="$PATH:~/.hermes"

    echo "Setting up Hermes config..."
    cp tests/v15_upgrade/hermes-config.toml ~/.hermes/config.toml

    echo "Adding relayer keys..."
    echo $MNEMONIC_RELAYER > mnemonic.txt
    hermes keys add --chain $CHAIN_ID --mnemonic-file mnemonic.txt
    hermes keys add --chain one-v120 --mnemonic-file mnemonic.txt
    hermes keys add --chain two-v200 --mnemonic-file mnemonic.txt
    hermes keys add --chain three-v310 --mnemonic-file mnemonic.txt
    hermes keys add --chain four-v200 --mnemonic-file mnemonic.txt
    hermes keys add --chain five --mnemonic-file mnemonic.txt
    hermes keys add --chain six-v310 --mnemonic-file mnemonic.txt
    hermes keys add --chain seven-v320 --mnemonic-file mnemonic.txt
    hermes keys add --chain eight-v330 --mnemonic-file mnemonic.txt
    hermes keys add --chain pfm1 --mnemonic-file mnemonic.txt
    hermes keys add --chain pfm2 --mnemonic-file mnemonic.txt
    hermes keys add --chain pfm3 --mnemonic-file mnemonic.txt

elif [ $RELAYER == "rly" ]; then

    echo "Downloading rly..."
    RLY_DOWNLOAD_URL="https://github.com/cosmos/relayer/releases/download/v${RLY_VERSION}/Cosmos.Relayer_${RLY_VERSION}_linux_amd64.tar.gz"
    wget $RLY_DOWNLOAD_URL -O rly-v$RLY_VERSION.tar.gz
    tar -xzvf rly-v$RLY_VERSION.tar.gz
    mkdir -p ~/.relayer
    mv Cosmos*/rly ~/.relayer/rly

    echo "Setting up rly config..."
    rly config init

    echo "Adding chains to config..."
    # provider
    rly chains add --file rly-chain-template.json

    # three
    jq '.value."chain-id" = "three-v310"' tests/v15_upgrade/rly-chain-template.json > three-1.json
    jq '.value."rpc-addr" = "http://localhost:27301"' three-1 > three-2.json
    jq '.value."gas-prices" = "0.005ucon"' three-2 > three-3.json
    rly chains add --file three-3.json

    echo "Adding relayer keys..."
    rly keys restore $CHAIN_ID default "$RELAYER_MNEMONIC"
    rly keys restore three-v310 default "$RELAYER_MNEMONIC"
fi

echo "Creating service..."
sudo touch /etc/systemd/system/$RELAYER.service
echo "[Unit]"                               | sudo tee /etc/systemd/system/$RELAYER.service
echo "Description=Relayer service"          | sudo tee /etc/systemd/system/$RELAYER.service -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$RELAYER.service -a
echo ""                                     | sudo tee /etc/systemd/system/$RELAYER.service -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$RELAYER.service -a
echo "User=$USER"                           | sudo tee /etc/systemd/system/$RELAYER.service -a

if [ $RELAYER == "hermes" ]; then
    echo "ExecStart=$HOME/.hermes/$RELAYER start"    | sudo tee /etc/systemd/system/$RELAYER.service -a
elif [ $RELAYER == "rly" ]; then
    echo "ExecStart=$HOME/.relayer/$RELAYER start"   | sudo tee /etc/systemd/system/$RELAYER.service -a
fi
echo "Restart=no"                           | sudo tee /etc/systemd/system/$RELAYER.service -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$RELAYER.service -a
echo ""                                     | sudo tee /etc/systemd/system/$RELAYER.service -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$RELAYER.service -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$RELAYER.service -a

sudo systemctl daemon-reload
sudo systemctl enable $RELAYER

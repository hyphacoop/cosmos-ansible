#!/bin/bash
# Set up a relayer

if [ $RELAYER == "hermes" ]; then

    echo "Downloading Hermes..."
    wget -q https://github.com/informalsystems/hermes/releases/download/$HERMES_VERSION/hermes-$HERMES_VERSION-x86_64-unknown-linux-gnu.tar.gz -O hermes-$HERMES_VERSION.tar.gz
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
    hermes keys add --chain four-v330 --mnemonic-file mnemonic.txt
    hermes keys add --chain five --mnemonic-file mnemonic.txt
    hermes keys add --chain six-v310 --mnemonic-file mnemonic.txt
    hermes keys add --chain seven-v320 --mnemonic-file mnemonic.txt
    hermes keys add --chain eight-v330 --mnemonic-file mnemonic.txt
    hermes keys add --chain nine-v400 --mnemonic-file mnemonic.txt
    hermes keys add --chain ten-v400 --mnemonic-file mnemonic.txt
    hermes keys add --chain pfm1 --mnemonic-file mnemonic.txt
    hermes keys add --chain pfm2 --mnemonic-file mnemonic.txt
    hermes keys add --chain pfm3 --mnemonic-file mnemonic.txt

elif [ $RELAYER == "rly" ]; then

    echo "Downloading rly..."
    RLY_DOWNLOAD_URL="https://github.com/cosmos/relayer/releases/download/v${RLY_VERSION}/Cosmos.Relayer_${RLY_VERSION}_linux_amd64.tar.gz"
    wget -q $RLY_DOWNLOAD_URL -O rly-v$RLY_VERSION.tar.gz
    tar -xzvf rly-v$RLY_VERSION.tar.gz
    mkdir -p ~/.relayer
    mv Cosmos*/rly ~/.relayer/rly

    echo "Setting up rly config..."
    rly config init

    echo "Adding chains to config..."
    # provider
    rly chains add --file tests/v15_upgrade/testnet.json

    # two
    # jq '.value."chain-id" = "two-v200"' tests/v15_upgrade/testnet.json > two-1.json
    # jq '.value."rpc-addr" = "http://localhost:27201"' two-1.json > two-2.json
    # jq '.value."gas-prices" = "0.005ucon"' two-2.json > two-v200.json
    # cat two-v200.json
    # rly chains add --file two-v200.json

    # three
    jq '.value."chain-id" = "three-v310"' tests/v15_upgrade/testnet.json > three-1.json
    jq '.value."rpc-addr" = "http://localhost:27301"' three-1.json > three-2.json
    jq '.value."gas-prices" = "0.005ucon"' three-2.json > three-v310.json
    cat three-v310.json
    rly chains add --file three-v310.json

    # four
    jq '.value."chain-id" = "four-v330"' tests/v15_upgrade/testnet.json > four-1.json
    jq '.value."rpc-addr" = "http://localhost:27401"' four-1.json > four-2.json
    jq '.value."gas-prices" = "0.005ucon"' four-2.json > four-v330.json
    cat four-v330.json
    rly chains add --file four-v330.json

    # five - Stride
    jq '.value."chain-id" = "five"' tests/v15_upgrade/testnet.json > five-1.json
    jq '.value."rpc-addr" = "http://localhost:27501"' five-1.json > five-2.json
    jq '.value."account-prefix" = "stride"' five-2.json > five-3.json
    jq '.value."gas-prices" = "0.0025ustrd"' five-3.json > five.json
    cat five.json
    rly chains add --file five.json

    # six
    jq '.value."chain-id" = "six-v310"' tests/v15_upgrade/testnet.json > six-1.json
    jq '.value."rpc-addr" = "http://localhost:27601"' six-1.json > six-2.json
    jq '.value."gas-prices" = "0.005ucon"' six-2.json > six-v310.json
    cat six-v310.json
    rly chains add --file six-v310.json

    # eight
    jq '.value."chain-id" = "eight-v330"' tests/v15_upgrade/testnet.json > eight-1.json
    jq '.value."rpc-addr" = "http://localhost:27801"' eight-1.json > eight-2.json
    jq '.value."gas-prices" = "0.005ucon"' eight-2.json > eight-v330.json
    cat eight-v330.json
    rly chains add --file eight-v330.json

    # nine
    jq '.value."chain-id" = "nine-v400"' tests/v15_upgrade/testnet.json > nine-1.json
    jq '.value."rpc-addr" = "http://localhost:27901"' nine-1.json > nine-2.json
    jq '.value."account-prefix" = "consumer"' nine-2.json > nine-3.json
    jq '.value."gas-prices" = "0.005ucon"' nine-3.json > nine-v400.json
    cat nine-v400.json
    rly chains add --file nine-v400.json

    # ten
    jq '.value."chain-id" = "ten-v400"' tests/v15_upgrade/testnet.json > ten-1.json
    jq '.value."rpc-addr" = "http://localhost:47901"' ten-1.json > ten-2.json
    jq '.value."account-prefix" = "consumer"' ten-2.json > ten-3.json
    jq '.value."gas-prices" = "0.005ucon"' ten-3.json > ten-v400.json
    cat ten-v400.json
    rly chains add --file ten-v400.json

    # pfm-1
    jq '.value."chain-id" = "pfm1"' tests/v15_upgrade/testnet.json > p.json
    jq '.value."rpc-addr" = "http://localhost:27011"' p.json > pf.json
    jq '.value."gas-prices" = "0.005uatom"' pf.json > pfm1.json
    rly chains add --file pfm1.json

    # pfm-2
    jq '.value."chain-id" = "pfm2"' tests/v15_upgrade/testnet.json > p.json
    jq '.value."rpc-addr" = "http://localhost:27012"' p.json > pf.json
    jq '.value."gas-prices" = "0.005uatom"' pf.json > pfm2.json
    rly chains add --file pfm2.json

    # pfm-3
    jq '.value."chain-id" = "pfm3"' tests/v15_upgrade/testnet.json > p.json
    jq '.value."rpc-addr" = "http://localhost:27013"' p.json > pf.json
    jq '.value."gas-prices" = "0.005uatom"' pf.json > pfm3.json
    rly chains add --file pfm3.json

    cat ~/.relayer/config/config.yaml

    echo "Adding relayer keys..."
    rly keys restore $CHAIN_ID default "$MNEMONIC_RELAYER"
    # rly keys restore two-v200 default "$MNEMONIC_RELAYER"
    rly keys restore three-v310 default "$MNEMONIC_RELAYER"
    rly keys restore four-v330 default "$MNEMONIC_RELAYER"
    rly keys restore five default "$MNEMONIC_RELAYER"
    rly keys restore six-v310 default "$MNEMONIC_RELAYER"
    rly keys restore eight-v330 default "$MNEMONIC_RELAYER"
    rly keys restore nine-v400 default "$MNEMONIC_RELAYER"
    rly keys restore ten-v400 default "$MNEMONIC_RELAYER"
    rly keys restore pfm1 default "$MNEMONIC_RELAYER"
    rly keys restore pfm2 default "$MNEMONIC_RELAYER"
    rly keys restore pfm3 default "$MNEMONIC_RELAYER"
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

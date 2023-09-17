#!/bin/bash
# Set up a relayer and IBC channels

PROVIDER_CLIENT=$1

# Clear existing installation
sudo systemctl disable hermes --now
sudo rm /etc/systemd/system/hermes.service
rm -rf ~/.hermes
rm hermes
rm hermes*gz

echo "Downloading Hermes..."
wget https://github.com/informalsystems/hermes/releases/download/$HERMES_VERSION/hermes-$HERMES_VERSION-x86_64-unknown-linux-gnu.tar.gz -O hermes-$HERMES_VERSION.tar.gz
tar -xzvf hermes-$HERMES_VERSION.tar.gz
mkdir -p ~/.hermes
cp hermes ~/.hermes/hermes
export PATH="$PATH:~/.hermes"

echo "Setting up Hermes config..."
cp tests/v13_upgrade/hermes-config.toml ~/.hermes/config.toml

echo "Adding relayer keys..."
echo $MNEMONIC_4 > mnemonic.txt
hermes keys add --chain $CHAIN_ID --mnemonic-file mnemonic.txt
hermes keys add --chain one-v120 --mnemonic-file mnemonic.txt
hermes keys add --chain two-v200 --mnemonic-file mnemonic.txt
hermes keys add --chain three-v310 --mnemonic-file mnemonic.txt
hermes keys add --chain four-v200 --mnemonic-file mnemonic.txt
hermes keys add --chain five --mnemonic-file mnemonic.txt
hermes keys add --chain six-v310 --mnemonic-file mnemonic.txt

echo "Creating service..."
sudo touch /etc/systemd/system/hermes.service
echo "[Unit]"                               | sudo tee /etc/systemd/system/hermes.service
echo "Description=Hermes service"           | sudo tee /etc/systemd/system/hermes.service -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/hermes.service -a
echo ""                                     | sudo tee /etc/systemd/system/hermes.service -a
echo "[Service]"                            | sudo tee /etc/systemd/system/hermes.service -a
echo "User=$USER"                           | sudo tee /etc/systemd/system/hermes.service -a
echo "ExecStart=$HOME/.hermes/hermes --config $HOME/.hermes/config.toml start" | sudo tee /etc/systemd/system/hermes.service -a
echo "Restart=no"                           | sudo tee /etc/systemd/system/hermes.service -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/hermes.service -a
echo ""                                     | sudo tee /etc/systemd/system/hermes.service -a
echo "[Install]"                            | sudo tee /etc/systemd/system/hermes.service -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/hermes.service -a

sudo systemctl daemon-reload
sudo systemctl enable hermes

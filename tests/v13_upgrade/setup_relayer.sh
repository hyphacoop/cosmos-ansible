#!/bin/bash
# Set up a relayer and IBC channels

PROVIDER_CLIENT=$1

# Clear existing installation
# sudo systemctl disable hermes --now
# sudo rm /etc/systemd/system/hermes.service
# rm -rf ~/.hermes
# rm hermes
# rm hermes*gz

echo "Downloading Hermes..."
mkdir -p ~/.hermes
# wget https://github.com/informalsystems/hermes/releases/download/$HERMES_VERSION/hermes-$HERMES_VERSION-x86_64-unknown-linux-gnu.tar.gz -O hermes-$HERMES_VERSION.tar.gz
# tar -xzvf hermes-$HERMES_VERSION.tar.gz
# cp hermes ~/.hermes/hermes
wget https://github.com/hyphacoop/cosmos-builds/releases/download/hermes-preview/hermes-preview -O ~/.hermes/hermes
chmod +x ~/.hermes/hermes
export PATH="$PATH:~/.hermes"

echo "Setting up Hermes config..."
cp tests/v13_upgrade/hermes-config.toml ~/.hermes/config.toml

echo "Adding relayer keys..."
echo $MNEMONIC_4 > mnemonic.txt
hermes keys add --chain $CHAIN_ID --mnemonic-file mnemonic.txt
hermes keys add --chain consumera --mnemonic-file mnemonic.txt
hermes keys add --chain consumerb --mnemonic-file mnemonic.txt
hermes keys add --chain consumerc --mnemonic-file mnemonic.txt
hermes keys add --chain consumerd --mnemonic-file mnemonic.txt

echo "Creating services..."
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

sudo touch /etc/systemd/system/hermes-evidence-b.service
echo "[Unit]"                               | sudo tee /etc/systemd/system/hermes-evidence-b.service
echo "Description=Hermes service"           | sudo tee /etc/systemd/system/hermes-evidence-b.service -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/hermes-evidence-b.service -a
echo ""                                     | sudo tee /etc/systemd/system/hermes-evidence-b.service -a
echo "[Service]"                            | sudo tee /etc/systemd/system/hermes-evidence-b.service -a
echo "User=$USER"                           | sudo tee /etc/systemd/system/hermes-evidence-b.service -a
echo "ExecStart=$HOME/.hermes/hermes --config $HOME/.hermes/config.toml evidence --chain consumerb" | sudo tee /etc/systemd/system/hermes-evidence-b.service -a
echo "Restart=no"                           | sudo tee /etc/systemd/system/hermes-evidence-b.service -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/hermes-evidence-b.service -a
echo ""                                     | sudo tee /etc/systemd/system/hermes-evidence-b.service -a
echo "[Install]"                            | sudo tee /etc/systemd/system/hermes-evidence-b.service -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/hermes-evidence-b.service -a

sudo systemctl daemon-reload
sudo systemctl enable hermes
sudo systemctl enable hermes-evidence-b

#!/bin/bash
# Upgrade half of the validators

echo "Upgrading half of the validators..."

# Download snapshot
# UPGRADE_BINARY_URL=https://github.com/hyphacoop/cosmos-builds/releases/download/gaiad-linux-$TARGET_BRANCH/gaiad-linux
wget $UPGRADE_BINARY_URL -O $HOME/upgrade-binary
chmod +x $HOME/upgrade-binary

sudo systemctl disable $PROVIDER_SERVICE_2 --now
sudo rm /etc/systemd/system/$PROVIDER_SERVICE_2
sudo touch /etc/systemd/system/$PROVIDER_SERVICE_2
echo "[Unit]"                               | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2
echo "Description=Consumer service"       | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo ""                                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "ExecStart=$HOME/upgrade-binary start --x-crisis-skip-assert-invariants --home $HOME_2" | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "Restart=no"                       | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo ""                                     | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$PROVIDER_SERVICE_2 -a

sudo systemctl daemon-reload
sudo systemctl enable $PROVIDER_SERVICE_2 --now

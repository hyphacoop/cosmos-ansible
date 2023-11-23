#!/bin/bash
# Test equivocation proposal for double-signing

UNBOND_AMOUNT=10000000
REDELEGATE_AMOUNT=5000000
SLASH_FACTOR=0.05

source tests/process_tx.sh

echo "Setting up provider node..."
$CHAIN_BINARY config chain-id $CHAIN_ID --home $EQ_PROVIDER_HOME
$CHAIN_BINARY config keyring-backend test --home $EQ_PROVIDER_HOME
$CHAIN_BINARY config broadcast-mode block --home $EQ_PROVIDER_HOME
$CHAIN_BINARY config node tcp://localhost:$EQ_PROV_RPC_PORT --home $EQ_PROVIDER_HOME
$CHAIN_BINARY init malval_det --chain-id $CHAIN_ID --home $EQ_PROVIDER_HOME

echo "Copying snapshot from validator 2..."
sudo systemctl stop $PROVIDER_SERVICE_2
cp -R $HOME_2/data/application.db $EQ_PROVIDER_HOME/data/
cp -R $HOME_2/data/blockstore.db $EQ_PROVIDER_HOME/data/
cp -R $HOME_2/data/cs.wal $EQ_PROVIDER_HOME/data/
cp -R $HOME_2/data/evidence.db $EQ_PROVIDER_HOME/data/
cp -R $HOME_2/data/snapshots $EQ_PROVIDER_HOME/data/
cp -R $HOME_2/data/state.db $EQ_PROVIDER_HOME/data/
cp -R $HOME_2/data/tx_index.db $EQ_PROVIDER_HOME/data/
cp -R $HOME_2/data/upgrade-info.json $EQ_PROVIDER_HOME/data/
sudo systemctl start $PROVIDER_SERVICE_2
sleep 10

echo "Getting genesis file..."
cp $HOME_1/config/genesis.json $EQ_PROVIDER_HOME/config/genesis.json

echo "Patching config files..."
# app.toml
# minimum_gas_prices
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"0.0025$DENOM\"^" $EQ_PROVIDER_HOME/config/app.toml
# Enable API
toml set --toml-path $EQ_PROVIDER_HOME/config/app.toml api.enable true
# Set different ports for api
toml set --toml-path $EQ_PROVIDER_HOME/config/app.toml api.address "tcp://0.0.0.0:$EQ_PROV_API_PORT"
# Set different ports for grpc
toml set --toml-path $EQ_PROVIDER_HOME/config/app.toml grpc.address "0.0.0.0:$EQ_PROV_GRPC_PORT"
# Turn off grpc web
toml set --toml-path $EQ_PROVIDER_HOME/config/app.toml grpc-web.enable false
# config.toml
# Set different ports for rpc
toml set --toml-path $EQ_PROVIDER_HOME/config/config.toml rpc.laddr "tcp://0.0.0.0:$EQ_PROV_RPC_PORT"
# Set different ports for rpc pprof
toml set --toml-path $EQ_PROVIDER_HOME/config/config.toml rpc.pprof_laddr "localhost:$EQ_PROV_PPROF_PORT"
# Set different ports for p2p
toml set --toml-path $EQ_PROVIDER_HOME/config/config.toml p2p.laddr "tcp://0.0.0.0:$EQ_PROV_P2P_PORT"
# Allow duplicate IPs in p2p
toml set --toml-path $EQ_PROVIDER_HOME/config/config.toml p2p.allow_duplicate_ip true
echo "Setting a short commit timeout..."
seconds=s
toml set --toml-path $EQ_PROVIDER_HOME/config/config.toml consensus.timeout_commit "$COMMIT_TIMEOUT$seconds"
# Set persistent peers
echo "Setting persistent peers..."
VAL2_NODE_ID=$($CHAIN_BINARY tendermint show-node-id --home $HOME_2)
VAL3_NODE_ID=$($CHAIN_BINARY tendermint show-node-id --home $HOME_3)
VAL2_PEER="$VAL2_NODE_ID@localhost:$VAL2_P2P_PORT"
VAL3_PEER="$VAL3_NODE_ID@localhost:$VAL3_P2P_PORT"
toml set --toml-path $EQ_PROVIDER_HOME/config/config.toml p2p.persistent_peers "$VAL2_PEER,$VAL3_PEER"
# Set fast_sync to false
toml set --toml-path $EQ_PROVIDER_HOME/config/config.toml fast_sync false

echo "Create new validator key..."
$CHAIN_BINARY keys add malval_det --home $EQ_PROVIDER_HOME
malval_det=$($CHAIN_BINARY keys list --home $EQ_PROVIDER_HOME --output json | jq -r '.[] | select(.name=="malval_det").address')

echo "Fund new validator..."
submit_tx "tx bank send $WALLET_1 $malval_det 100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $HIGH_FEES$DENOM -o json -y" $CHAIN_BINARY $HOME_1

echo "Setting up service..."

sudo touch /etc/systemd/system/$EQ_PROVIDER_SERVICE
echo "[Unit]"                               | sudo tee /etc/systemd/system/$EQ_PROVIDER_SERVICE
echo "Description=Gaia service"             | sudo tee /etc/systemd/system/$EQ_PROVIDER_SERVICE -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$EQ_PROVIDER_SERVICE -a
echo ""                                     | sudo tee /etc/systemd/system/$EQ_PROVIDER_SERVICE -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$EQ_PROVIDER_SERVICE -a
echo "User=$USER"                           | sudo tee /etc/systemd/system/$EQ_PROVIDER_SERVICE -a
echo "ExecStart=$HOME/go/bin/$CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $EQ_PROVIDER_HOME" | sudo tee /etc/systemd/system/$EQ_PROVIDER_SERVICE -a
echo "Restart=no"                           | sudo tee /etc/systemd/system/$EQ_PROVIDER_SERVICE -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$EQ_PROVIDER_SERVICE -a
echo ""                                     | sudo tee /etc/systemd/system/$EQ_PROVIDER_SERVICE -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$EQ_PROVIDER_SERVICE -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$EQ_PROVIDER_SERVICE -a

echo "Starting provider service..."
sudo systemctl enable $EQ_PROVIDER_SERVICE --now

sleep 20
$CHAIN_BINARY q block --home $EQ_PROVIDER_HOME | jq '.'
curl http://localhost:$EQ_PROV_RPC_PORT/status | jq -r '.result.sync_info'

echo "Create validator..."
total_before=$(curl http://localhost:$CON1_RPC_PORT/validators | jq -r '.result.total')
$CHAIN_BINARY tx staking create-validator --amount 50000000$DENOM \
--pubkey $($CHAIN_BINARY tendermint show-validator --home $EQ_PROVIDER_HOME) \
--moniker malval_det --chain-id $CHAIN_ID \
--commission-rate 0.10 --commission-max-rate 0.20 --commission-max-change-rate 0.01 \
--gas auto --gas-adjustment $GAS_ADJUSTMENT --fees 2000$DENOM --from $malval_det --home $EQ_PROVIDER_HOME -b block -y
sleep 90

echo "Check validator is in the consumer chain..."
total_after=$(curl http://localhost:$CON1_RPC_PORT/validators | jq -r '.result.total')
total=$(( $total_after - $total_before ))

if [ $total == 1 ]; then
  echo "Validator created!"
else
  echo "Validator not created."
  exit 1
fi

echo "Setting up consumer node..."
$CONSUMER_CHAIN_BINARY config chain-id $CONSUMER_CHAIN_ID --home $EQ_CONSUMER_HOME_1
$CONSUMER_CHAIN_BINARY config keyring-backend test --home $EQ_CONSUMER_HOME_1
$CONSUMER_CHAIN_BINARY config node tcp://localhost:$EQ_CON_RPC_PORT_1 --home $EQ_CONSUMER_HOME_1
$CONSUMER_CHAIN_BINARY init malval_det --chain-id $CONSUMER_CHAIN_ID --home $EQ_CONSUMER_HOME_1

echo "Submit key assignment transaction..."
key=$($CONSUMER_CHAIN_BINARY tendermint show-validator --home $EQ_CONSUMER_HOME_1)
echo "Consumer key: $key"
command="$CHAIN_BINARY tx provider assign-consensus-key $CONSUMER_CHAIN_ID $key --from $malval_det --gas auto --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --home $EQ_PROVIDER_HOME -y"
echo $command
$command

sleep 12
$CHAIN_BINARY q provider validator-consumer-key $CONSUMER_CHAIN_ID $($CHAIN_BINARY tendermint show-address --home $EQ_PROVIDER_HOME) --home $HOME_1

echo "Getting patched genesis file..."
cp $CONSUMER_HOME_1/config/genesis.json $EQ_CONSUMER_HOME_1/config/genesis.json

echo "Patching config files..."
# app.toml
# minimum_gas_prices
sed -i -e "/minimum-gas-prices =/ s^= .*^= \"0$CONSUMER_DENOM\"^" $EQ_CONSUMER_HOME_1/config/app.toml
# Enable API
toml set --toml-path $EQ_CONSUMER_HOME_1/config/app.toml api.enable true
# Set different ports for api
toml set --toml-path $EQ_CONSUMER_HOME_1/config/app.toml api.address "tcp://0.0.0.0:$EQ_CON_API_PORT_1"
# Set different ports for grpc
toml set --toml-path $EQ_CONSUMER_HOME_1/config/app.toml grpc.address "0.0.0.0:$EQ_CON_GRPC_PORT_1"
# Turn off grpc web
toml set --toml-path $EQ_CONSUMER_HOME_1/config/app.toml grpc-web.enable false
# config.toml
# Set different ports for rpc
toml set --toml-path $EQ_CONSUMER_HOME_1/config/config.toml rpc.laddr "tcp://0.0.0.0:$EQ_CON_RPC_PORT_1"
# Set different ports for rpc pprof
toml set --toml-path $EQ_CONSUMER_HOME_1/config/config.toml rpc.pprof_laddr "localhost:$EQ_CON_PPROF_PORT_1"
# Set different ports for p2p
toml set --toml-path $EQ_CONSUMER_HOME_1/config/config.toml p2p.laddr "tcp://0.0.0.0:$EQ_CON_P2P_PORT_1"
echo "Set no strict address book rules..."
toml set --toml-path $EQ_CONSUMER_HOME_1/config/config.toml p2p.addr_book_strict false
# Allow duplicate IPs in p2p
toml set --toml-path $EQ_CONSUMER_HOME_1/config/config.toml p2p.allow_duplicate_ip true
echo "Setting persistent peer..."
CON1_NODE_ID=$($CONSUMER_CHAIN_BINARY tendermint show-node-id --home $CONSUMER_HOME_1)
CON1_PEER="$CON1_NODE_ID@localhost:$CON1_P2P_PORT"
toml set --toml-path $EQ_CONSUMER_HOME_1/config/config.toml p2p.persistent_peers "$CON1_PEER"
echo "Setting a short commit timeout..."
toml set --toml-path $EQ_CONSUMER_HOME_1/config/config.toml consensus.timeout_commit "1s"
# Set fast_sync to false - or block_sync for ICS v3
toml set --toml-path $EQ_CONSUMER_HOME_1/config/config.toml fast_sync false
toml set --toml-path $EQ_CONSUMER_HOME_1/config/config.toml block_sync false

echo "Setting up services..."

sudo touch /etc/systemd/system/$EQ_CONSUMER_SERVICE_1
echo "[Unit]"                               | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_1
echo "Description=Consumer service"       | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_1 -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_1 -a
echo ""                                     | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_1 -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_1 -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_1 -a
echo "ExecStart=$HOME/go/bin/$CONSUMER_CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $EQ_CONSUMER_HOME_1" | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_1 -a
echo "Restart=no"                       | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_1 -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_1 -a
echo ""                                     | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_1 -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_1 -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_1 -a

sudo touch /etc/systemd/system/$EQ_CONSUMER_SERVICE_2
echo "[Unit]"                               | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_2
echo "Description=Consumer service"       | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_2 -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_2 -a
echo ""                                     | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_2 -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_2 -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_2 -a
echo "ExecStart=$HOME/go/bin/$CONSUMER_CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $EQ_CONSUMER_HOME_2" | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_2 -a
echo "Restart=no"                       | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_2 -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_2 -a
echo ""                                     | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_2 -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_2 -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$EQ_CONSUMER_SERVICE_2 -a

echo "Starting consumer service..."
sudo systemctl enable $EQ_CONSUMER_SERVICE_1 --now

sleep 20
$CONSUMER_CHAIN_BINARY q block --home $EQ_CONSUMER_HOME_1 | jq '.'

val_bytes=$($CHAIN_BINARY keys parse $malval_det --output json | jq -r '.bytes')
eq_valoper=$($CHAIN_BINARY keys parse $val_bytes --output json | jq -r '.formats[2]')
echo "Validator address: $eq_valoper"

$CHAIN_BINARY tx staking unbond $eq_valoper $UNBOND_AMOUNT$DENOM --from $malval_det --home $EQ_PROVIDER_HOME --gas auto --gas-adjustment 1.2 --fees 1000$DENOM -y
sleep 10
$CHAIN_BINARY tx staking redelegate $eq_valoper $VALOPER_3 $REDELEGATE_AMOUNT$DENOM --from $malval_det --home $EQ_PROVIDER_HOME --gas auto --gas-adjustment 1.2 --fees 1000$DENOM -y
sleep 10

start_tokens=$($CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r --arg oper "$eq_valoper" '.validators[] | select(.operator_address==$oper).tokens')
start_unbonding=$($CHAIN_BINARY q staking unbonding-delegations-from $eq_valoper --home $HOME_1 -o json | jq -r '.unbonding_responses[0].entries[0].balance')
start_redelegation_dest=$($CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r --arg oper "$VALOPER_3" '.validators[] | select(.operator_address==$oper).tokens')

echo "Attempting to double sign..."

# Stop whale
echo "Stopping whale validator..."
sudo systemctl stop $CONSUMER_SERVICE_1
sleep 10

# Stop validator
sudo systemctl stop $EQ_CONSUMER_SERVICE_1

# Duplicate home folder
echo "Duplicating home folder..."
cp -r $EQ_CONSUMER_HOME_1/ $EQ_CONSUMER_HOME_2/

# Update peer info
CON2_NODE_ID=$($CONSUMER_CHAIN_BINARY tendermint show-node-id --home $CONSUMER_HOME_2)
CON2_PEER="$CON2_NODE_ID@localhost:$CON2_P2P_PORT"
toml set --toml-path $EQ_CONSUMER_HOME_2/config/config.toml p2p.persistent_peers "$CON2_PEER"

# Update ports
toml set --toml-path $EQ_CONSUMER_HOME_2/config/app.toml api.address "tcp://0.0.0.0:$EQ_CON_API_PORT_2"
# Set different ports for grpc
toml set --toml-path $EQ_CONSUMER_HOME_2/config/app.toml grpc.address "0.0.0.0:$EQ_CON_GRPC_PORT_2"
# config.toml
# Set different ports for rpc
toml set --toml-path $EQ_CONSUMER_HOME_2/config/config.toml rpc.laddr "tcp://0.0.0.0:$EQ_CON_RPC_PORT_2"
# Set different ports for rpc pprof
toml set --toml-path $EQ_CONSUMER_HOME_2/config/config.toml rpc.pprof_laddr "localhost:$EQ_CON_PPROF_PORT_2"
# Set different ports for p2p
toml set --toml-path $EQ_CONSUMER_HOME_2/config/config.toml p2p.laddr "tcp://0.0.0.0:$EQ_CON_P2P_PORT_2"

# Wipe the state and address books
echo '{"height": "0","round": 0,"step": 0,"signature":"","signbytes":""}' > $EQ_CONSUMER_HOME_2/data/priv_validator_state.json
echo "{}" > $EQ_CONSUMER_HOME_2/config/addrbook.json
echo "{}" > $EQ_CONSUMER_HOME_1/config/addrbook.json

# Start duplicate
echo "Starting second node..."
sudo systemctl enable $EQ_CONSUMER_SERVICE_2 --now
sleep 10

# Start original
echo "Starting first node..."
sudo systemctl start $EQ_CONSUMER_SERVICE_1
sleep 30

# Restart whale
echo "Restarting whale validator..."
sudo systemctl start $CONSUMER_SERVICE_1
sleep 90

# echo "con1 log:"
# journalctl -u $CONSUMER_SERVICE_1 | tail -n 50
# echo con2 log:
# journalctl -u $CONSUMER_SERVICE_2 | tail -n 50
echo "Original log:"
journalctl -u $EQ_CONSUMER_SERVICE_1 | tail -n 50
echo "Double log:"
journalctl -u $EQ_CONSUMER_SERVICE_2 | tail -n 50

$CONSUMER_CHAIN_BINARY q evidence --home $CONSUMER_HOME_1 -o json | jq '.'
consensus_address=$($CONSUMER_CHAIN_BINARY tendermint show-address --home $EQ_CONSUMER_HOME_1)
validator_check=$($CONSUMER_CHAIN_BINARY q evidence --home $CONSUMER_HOME_1 -o json | jq '.' | grep $consensus_address)
echo $validator_check
if [ -z "$validator_check" ]; then
  echo "No equivocation evidence found."
  exit 1
else
  echo "Equivocation evidence found!"
fi

echo "Wait for evidence to reach the provider chain..."
sleep 60

journalctl -u hermes-evidence

status=$($CHAIN_BINARY q slashing signing-info $($CHAIN_BINARY tendermint show-validator --home $EQ_PROVIDER_HOME) --home $HOME_1 -o json | jq '.tombstoned')
echo "Status: $status"
if [ $status == "true" ]; then
  echo "Success: validator has been tombstoned!"
else
  echo "Failure: validator was not tombstoned."
  exit 1
fi

echo "Slashing checks:"
end_tokens=$($CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r --arg oper "$eq_valoper" '.validators[] | select(.operator_address==$oper).tokens')
end_unbonding=$($CHAIN_BINARY q staking unbonding-delegations-from $eq_valoper --home $HOME_1 -o json | jq -r '.unbonding_responses[0].entries[0].balance')
end_redelegation_dest=$($CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r --arg oper "$VALOPER_3" '.validators[] | select(.operator_address==$oper).tokens')

echo "Validator tokens: $start_tokens -> $end_tokens"
echo "Unbonding delegations: $start_unbonding -> $end_unbonding"
echo "Redelegation recipient: $start_redelegation_dest -> $end_redelegation_dest"

expected_slashed_tokens=$(echo "$SLASH_FACTOR * $start_tokens" | bc -l)
expected_slashed_unbonding=$(echo "$SLASH_FACTOR * $start_unbonding" | bc -l)
expected_slashed_redelegation=$(echo "$SLASH_FACTOR * $REDELEGATE_AMOUNT" | bc -l)
expected_slashed_total=$(echo "$SLASH_FACTOR * ($start_tokens + $start_unbonding + $REDELEGATE_AMOUNT)" | bc -l)

bonded_tokens_slashed=$(echo "$start_tokens - $end_tokens" | bc)
unbonding_slashed=$(echo "$start_unbonding - $end_unbonding" | bc)
redelegation_dest_slashed=$(echo "$start_redelegation_dest - $end_redelegation_dest" | bc)
total_slashed=$(echo "$bonded_tokens_slashed + $unbonding_slashed + $redelegation_dest_slashed" | bc -l)
echo "Tokens slashed: $bonded_tokens_slashed, expected: $expected_slashed_tokens"
echo "Unbonding delegations slashed: $unbonding_slashed, expected: $expected_slashed_unbonding"
echo "Redelegations slashed: $redelegation_dest_slashed, expected: $expected_slashed_redelegation"
echo "Total slashed: $total_slashed, expected: $expected_slashed_total"

if [[ $total_slashed -ne ${expected_slashed_total%.*} ]]; then
  echo "Total slashed tokens does not match expected value."
  exit 1
else
  echo "Total slashed tokens: pass"
fi

if [[ $bonded_tokens_slashed -ne ${expected_slashed_tokens%.*} ]]; then
  echo "Slashed bonded tokens does not match expected value."
  exit 1
else
  echo "Slashed bonded tokens: pass"
fi

if [[ $unbonding_slashed -ne ${expected_slashed_unbonding%.*} ]]; then
  echo "Slashed unbonding tokens does not match expected value."
  exit 1
else
  echo "Slashed unbonding tokens: pass"
fi

if [[ $redelegation_dest_slashed -ne ${expected_slashed_redelegation%.*} ]]; then
  echo "Slashed redelegation tokens does not match expected value."
  exit 1
else
  echo "Slashed redelegation tokens: pass"
fi

sudo systemctl disable $EQ_PROVIDER_SERVICE --now
sudo systemctl disable $EQ_CONSUMER_SERVICE_1 --now
sudo systemctl disable $EQ_CONSUMER_SERVICE_2 --now
rm -rf $EQ_PROVIDER_HOME
rm -rf $EQ_CONSUMER_HOME_1
rm -rf $EQ_CONSUMER_HOME_2
sudo rm /etc/systemd/system/$EQ_PROVIDER_SERVICE
sudo rm /etc/systemd/system/$EQ_CONSUMER_SERVICE_1
sudo rm /etc/systemd/system/$EQ_CONSUMER_SERVICE_2

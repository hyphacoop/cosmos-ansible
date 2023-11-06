#!/bin/bash

UNBOND_AMOUNT_1=10000000
UNBOND_AMOUNT_2=2000000
REDELEGATE_AMOUNT=5000000
SLASH_FACTOR=0.05

$CHAIN_BINARY tx staking unbond $VALOPER_1 $UNBOND_AMOUNT_1$DENOM --from $WALLET_1 --home $HOME_1 --gas auto --gas-adjustment 1.2 --fees 1000$DENOM -y
sleep 10
$CHAIN_BINARY tx staking redelegate $VALOPER_1 $VALOPER_3 $REDELEGATE_AMOUNT$DENOM --from $WALLET_1 --home $HOME_1 --gas auto --gas-adjustment 1.2 --fees 1000$DENOM -y
sleep 10
$CHAIN_BINARY tx staking unbond $VALOPER_2 $UNBOND_AMOUNT_2$DENOM --from $WALLET_2 --home $HOME_1 --gas auto --gas-adjustment 1.2 --fees 1000$DENOM -y
sleep 10

start_tokens_1=$($CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r --arg oper "$VALOPER_1" '.validators[] | select(.operator_address==$oper).tokens')
start_tokens_2=$($CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r --arg oper "$VALOPER_2" '.validators[] | select(.operator_address==$oper).tokens')
start_unbonding_1=$($CHAIN_BINARY q staking unbonding-delegations-from $VALOPER_1 --home $HOME_1 -o json | jq -r '.unbonding_responses[0].entries[0].balance')
start_unbonding_2=$($CHAIN_BINARY q staking unbonding-delegations-from $VALOPER_2 --home $HOME_1 -o json | jq -r '.unbonding_responses[0].entries[0].balance')
start_redelegation_dest=$($CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r --arg oper "$VALOPER_3" '.validators[] | select(.operator_address==$oper).tokens')

# Validators 1 and 2 will copy the chain

echo "0. Get trusted height"
TRUSTED_HEIGHT=$(hermes --json --config ~/.hermes/config.toml query client consensus --chain $CHAIN_ID --client 07-tendermint-0 | tail -n 1 | jq '.result[2].revision_height')
echo "Trusted height: $TRUSTED_HEIGHT"

# echo "1. Stop $CONSUMER_SERVICE_1 and $CONSUMER_SERVICE_2..."
# sudo systemctl stop $CONSUMER_SERVICE_1
# sudo systemctl stop $CONSUMER_SERVICE_2

echo "2. Copy validator home folders..."
cp -r $CONSUMER_HOME_1 $CONSUMER_HOME_1F
cp -r $CONSUMER_HOME_2 $CONSUMER_HOME_2F

# echo "Start $CONSUMER_SERVICE_1 and $CONSUMER_SERVICE_2 again..."
# sudo systemctl start $CONSUMER_SERVICE_1
# sudo systemctl start $CONSUMER_SERVICE_2
# sleep 15

echo "3. Clear persistent peers..."
CON1_NODE_ID=$($CONSUMER_CHAIN_BINARY tendermint show-node-id --home $CONSUMER_HOME_1F)
CON2_NODE_ID=$($CONSUMER_CHAIN_BINARY tendermint show-node-id --home $CONSUMER_HOME_2F)
CON1_PEER="$CON1_NODE_ID@127.0.0.1:$CON1F_P2P_PORT"
CON2_PEER="$CON2_NODE_ID@127.0.0.1:$CON2F_P2P_PORT"
toml set --toml-path $CONSUMER_HOME_1F/config/config.toml p2p.persistent_peers "$CON2_PEER"
toml set --toml-path $CONSUMER_HOME_2F/config/config.toml p2p.persistent_peers "$CON1_PEER"

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

echo "6. Set up new services..."

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

echo "7. Update the light client of the consumer chain on the provider chain"
hermes --config ~/.hermes/config-2.toml update client --client 07-tendermint-0 --host-chain $CHAIN_ID --trusted-height $TRUSTED_HEIGHT

echo "Waiting for evidence to be sent to provider chain..."
sleep 30
sudo systemctl restart hermes
sleep 60

echo "Hermes:"
journalctl -u hermes | tail -n 100
echo "consumer 1:"
journalctl -u $CONSUMER_SERVICE_1 | tail -n 20
echo "consumer 1f:"
journalctl -u $CONSUMER_SERVICE_1F | tail -n 20
echo "validator 1:"
journalctl -u $PROVIDER_SERVICE_1 | tail -n 10

$CHAIN_BINARY q ibc client status 07-tendermint-0 --home $HOME_1
$CHAIN_BINARY q ibc client state 07-tendermint-0 -o json --home $HOME_1 | jq -r '.client_state.frozen_height'

$CHAIN_BINARY q slashing signing-infos --home $HOME_1

status=$($CHAIN_BINARY q slashing signing-info $($CHAIN_BINARY tendermint show-validator --home $HOME_1) --home $HOME_1 -o json | jq '.tombstoned')
echo "Status: $status"
if [ $status == "true" ]; then
  echo "Success: validator 1 has been tombstoned!"
else
  echo "Failure: validator 1 was not tombstoned."
  exit 1
fi

status=$($CHAIN_BINARY q slashing signing-info $($CHAIN_BINARY tendermint show-validator --home $HOME_2) --home $HOME_1 -o json | jq '.tombstoned')
echo "Status: $status"
if [ $status == "true" ]; then
  echo "Success: validator 2 has been tombstoned!"
else
  echo "Failure: validator 2 was not tombstoned."
  exit 1
fi

echo "Slashing checks:"
end_tokens_1=$($CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r --arg oper "$VALOPER_1" '.validators[] | select(.operator_address==$oper).tokens')
end_tokens_2=$($CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r --arg oper "$VALOPER_2" '.validators[] | select(.operator_address==$oper).tokens')
end_unbonding_1=$($CHAIN_BINARY q staking unbonding-delegations-from $VALOPER_1 --home $HOME_1 -o json | jq -r '.unbonding_responses[0].entries[0].balance')
end_unbonding_2=$($CHAIN_BINARY q staking unbonding-delegations-from $VALOPER_2 --home $HOME_1 -o json | jq -r '.unbonding_responses[0].entries[0].balance')
end_redelegation_dest=$($CHAIN_BINARY q staking validators --home $HOME_1 -o json | jq -r --arg oper "$VALOPER_3" '.validators[] | select(.operator_address==$oper).tokens')

echo "Validator 1 tokens: $start_tokens_1 -> $end_tokens_1"
echo "Validator 2 tokens: $start_tokens_1 -> $end_tokens_1"
echo "Validator 1 unbonding delegations: $start_unbonding_1 -> $end_unbonding_1"
echo "Validator 2 unbonding delegations: $start_unbonding_2 -> $end_unbonding_2"
echo "Redelegation recipient: $start_redelegation_dest -> $end_redelegation_dest"

expected_slashed_tokens_1=$(echo "$SLASH_FACTOR * $start_tokens_1" | bc -l)
expected_slashed_tokens_2=$(echo "$SLASH_FACTOR * $start_tokens_2" | bc -l)
expected_slashed_unbonding_1=$(echo "$SLASH_FACTOR * $start_unbonding_1" | bc -l)
expected_slashed_unbonding_2=$(echo "$SLASH_FACTOR * $start_unbonding_2" | bc -l)
expected_slashed_redelegation=$(echo "$SLASH_FACTOR * $REDELEGATE_AMOUNT" | bc -l)
expected_slashed_total_1=$(echo "$SLASH_FACTOR * ($start_tokens_1 + $start_unbonding_1 + $REDELEGATE_AMOUNT)" | bc -l)
expected_slashed_total_2=$(echo "$SLASH_FACTOR * ($start_tokens_2 + $start_unbonding_2)" | bc -l)

bonded_tokens_slashed_1=$(echo "$start_tokens_1 - $end_tokens_1" | bc)
bonded_tokens_slashed_2=$(echo "$start_tokens_2 - $end_tokens_2" | bc)
unbonding_slashed_1=$(echo "$start_unbonding_1 - $end_unbonding_1" | bc)
unbonding_slashed_2=$(echo "$start_unbonding_2 - $end_unbonding_2" | bc)
redelegation_dest_slashed=$(echo "$start_redelegation_dest - $end_redelegation_dest" | bc)
total_slashed_1=$(echo "$bonded_tokens_slashed_1 + $unbonding_slashed_1 + $redelegation_dest_slashed" | bc -l)
total_slashed_2=$(echo "$bonded_tokens_slashed_2 + $unbonding_slashed_2" | bc -l)
echo "Validator 1 tokens slashed: $bonded_tokens_slashed_1, expected: $expected_slashed_tokens_1"
echo "Validator 2 tokens slashed: $bonded_tokens_slashed_2, expected: $expected_slashed_tokens_2"
echo "Validator 1 unbonding delegations slashed: $unbonding_slashed_1, expected: $expected_slashed_unbonding_1"
echo "Validator 2 unbonding delegations slashed: $unbonding_slashed_2, expected: $expected_slashed_unbonding_2"
echo "Validator 1 redelegations slashed: $redelegation_dest_slashed, expected: $expected_slashed_redelegation"
echo "Validator 1 total slashed: $total_slashed_1, expected: $expected_slashed_total_1"
echo "Validator 2 total slashed: $total_slashed_2, expected: $expected_slashed_total_2"

if [[ $total_slashed_1 -ne ${expected_slashed_total_1%.*} ]]; then
  echo "Total slashed tokens does not match expected value - val1."
  exit 1
else
  echo "Total slashed tokens for val1: pass"
fi

if [[ $total_slashed_2 -ne ${expected_slashed_total_2%.*} ]]; then
  echo "Total slashed tokens does not match expected value - val2."
  exit 1
else
  echo "Total slashed tokens for val2: pass"
fi

if [[ $bonded_tokens_slashed_1 -ne ${expected_slashed_tokens_1%.*} ]]; then
  echo "Slashed bonded tokens does not match expected value - val1."
  exit 1
else
  echo "Slashed bonded tokens for val1: pass"
fi

if [[ $bonded_tokens_slashed_2 -ne ${expected_slashed_tokens_2%.*} ]]; then
  echo "Slashed bonded tokens does not match expected value - val2."
  exit 1
else
  echo "Slashed bonded tokens for val2: pass"
fi

if [[ $unbonding_slashed_1 -ne ${expected_slashed_unbonding_1%.*} ]]; then
  echo "Slashed unbonding tokens does not match expected value - val1."
  exit 1
else
  echo "Slashed unbonding tokens for val1: pass"
fi

if [[ $unbonding_slashed_2 -ne ${expected_slashed_unbonding_2%.*} ]]; then
  echo "Slashed unbonding tokens does not match expected value - val2."
  exit 1
else
  echo "Slashed unbonding tokens for val2: pass"
fi

if [[ $redelegation_dest_slashed -ne ${expected_slashed_redelegation%.*} ]]; then
  echo "Slashed redelegation tokens does not match expected value."
  exit 1
else
  echo "Slashed redelegation tokens: pass"
fi

client_status=$(hermes --json query client status --chain $CHAIN_ID --client 07-tendermint-0 | tail -n 1 | jq -r '.result')

if [[ "$client_status" != "Frozen" ]]; then
  echo "Failure: Client is not frozen."
  exit 1
else
  echo "Client is frozen."
fi

#!/bin/bash
# Launch a consumer chain

# $1 sets the backwards compatibility version

transform=$1

echo "Patching add template with spawn time..."
spawn_time=$(date -u --iso-8601=ns | sed s/+00:00/Z/ | sed s/,/./)
jq -r --arg SPAWNTIME "$spawn_time" '.spawn_time |= $SPAWNTIME' tests/patch_upgrade/proposal-add-template.json > proposal-add-spawn.json
sed "s%\"chain_id\": \"\"%\"chain_id\": \"$CONSUMER_CHAIN_ID\"%g" proposal-add-spawn.json > proposal-add-$CONSUMER_CHAIN_ID.json
rm proposal-add-spawn.json

echo "Proposal file proposal-add-$CONSUMER_CHAIN_ID.json"
jq -r '.' proposal-add-$CONSUMER_CHAIN_ID.json
cp proposal-add-$CONSUMER_CHAIN_ID.json ~/artifact/

echo "Submitting proposal..."
proposal="$CHAIN_BINARY tx gov submit-legacy-proposal consumer-addition proposal-add-$CONSUMER_CHAIN_ID.json --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --from $WALLET_1 --keyring-backend test --home $HOME_1 --chain-id $CHAIN_ID -b sync -y -o json"
echo $proposal
gaiadout=$($proposal)
echo "gaiad output:"
echo "$gaiadout"
echo "$gaiadout" > ~/artifact/$CONSUMER_CHAIN_ID-tx.txt

txhash=$(echo "$gaiadout" | jq -r .txhash)
# Wait for the proposal to go on chain
tests/test_block_production.sh 127.0.0.1 $VAL1_RPC_PORT 1 10

# Get proposal ID from txhash
echo "Getting proposal ID from txhash..."
$CHAIN_BINARY q tx $txhash --home $HOME_1
proposal_id=$($CHAIN_BINARY q tx $txhash --home $HOME_1 --output json | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')

echo "Voting on proposal $proposal_id..."
$CHAIN_BINARY tx gov vote $proposal_id yes --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --from $WALLET_1 --keyring-backend test --home $HOME_1 --chain-id $CHAIN_ID -b sync -y
$CHAIN_BINARY q gov tally $proposal_id --home $HOME_1

echo "Waiting for proposal to pass..."
sleep $VOTING_PERIOD
tests/test_block_production.sh 127.0.0.1 $VAL1_RPC_PORT 1 10

#$CHAIN_BINARY q gov proposals --home $HOME_1

echo "Collecting the CCV state..."
$CHAIN_BINARY q provider consumer-genesis $CONSUMER_CHAIN_ID -o json --home $HOME_1 > ccv-pre.json
jq '.params |= . + {"soft_opt_out_threshold": "0.05"}' ccv-pre.json > ccv.json
jq '.' ccv.json

if [ ! -z $transform ]
then
    echo "Patching CCV for backwards compatibility"
    wget https://github.com/hyphacoop/cosmos-builds/releases/download/ics-v3.3.0-transform/interchain-security-cd -O ics-transform
    chmod +x ics-transform
    ./ics-transform genesis transform --to $transform ccv.json > ccv-transform.json
    cp ccv-transform.json ccv.json
fi

echo "Patching the consumer genesis file..."
jq -s '.[0].app_state.ccvconsumer = .[1] | .[0]' $CONSUMER_HOME_1/config/genesis.json ccv.json > consumer-genesis.json
cp consumer-genesis.json $CONSUMER_HOME_1/config/genesis.json

echo "Starting the consumer chain..."
# Run service in screen session
echo "Starting $CONSUMER_CHAIN_BINARY"
screen -L -Logfile $HOME/artifact/$CONSUMER_SERVICE_1.log -S $CONSUMER_SERVICE_1 -d -m bash $HOME/$CONSUMER_SERVICE_1.sh
# set screen to flush log to 0
screen -r $CONSUMER_SERVICE_1 -p0 -X logfile flush 0

# sleep 20
# sudo journalctl -u $CONSUMER_SERVICE_1 | tail -n 200
# sudo journalctl -u $CONSUMER_SERVICE_2 | tail -n 200
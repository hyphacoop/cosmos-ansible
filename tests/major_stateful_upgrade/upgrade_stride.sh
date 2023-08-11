#!/bin/bash
# Prepare upgrade to v12
set -x

UPGRADE_NAME=v12
PROPOSAL_ID=1

voting_period=$($STRIDE_CHAIN_BINARY q gov params --home $STRIDE_HOME_1 -o json | jq -r '.voting_params.voting_period')
voting_period_seconds=${voting_period::-1}
height=$(curl -s http://localhost:$STRIDE_RPC_1/block | jq -r '.result.block.header.height')
let voting_blocks_delta=$voting_period_seconds*2
let upgrade_height=$height+$voting_blocks_delta

printf "Submitting proposal to upgrade at block height $upgrade_height...\n"
$STRIDE_CHAIN_BINARY tx gov submit-legacy-proposal software-upgrade $UPGRADE_NAME \
    --title $UPGRADE_NAME --description "test upgrade" --deposit 10000000$STRIDE_DENOM --no-validate \
    --upgrade-height $upgrade_height --from $MONIKER_1 -y --fees 500$STRIDE_DENOM --home $STRIDE_HOME_1 --chain-id $STRIDE_CHAIN_ID

sleep 3
printf "\nVoting on upgrade proposal...\n"
$STRIDE_CHAIN_BINARY tx gov vote $PROPOSAL_ID yes --from $MONIKER_1 -y --fees 500$STRIDE_DENOM --home $STRIDE_HOME_1 --chain-id $STRIDE_CHAIN_ID

printf "\nWaiting for proposal to pass...\n"
while true; do
    status=$($STRIDE_CHAIN_BINARY query gov proposal $PROPOSAL_ID --home $STRIDE_HOME_1 | grep "status" | awk '{printf $2}')
    if [[ "$status" == "PROPOSAL_STATUS_VOTING_PERIOD" ]]; then
        echo "Proposal still in progress..."
        sleep 1
    elif [[ "$status" == "PROPOSAL_STATUS_PASSED" ]]; then
        echo "Proposal passed!"
        break
    elif [[ "$status" == "PROPOSAL_STATUS_REJECTED" ]]; then
        echo "Proposal Failed!"
        exit 1
    else 
        echo "Unknown proposal status: $status"
        exit 1
    fi
done

printf "Waiting for upgrade height $upgrade_height to halt the chain...\n"
height=0
until [ $height -ge $upgrade_height ]
do
    sleep 1
    height=$(curl -s http://localhost:$STRIDE_RPC_1/block | jq -r '.result.block.header.height')
    printf "Stride height: $height\n"
done

printf "Stride has reached the upgrade height, stopping the service...\n"
killall $STRIDE_CHAIN_BINARY
screen -XS $STRIDE_SERVICE_1 quit
sleep 5
tail -n 50 $HOME/artifact/$STRIDE_SERVICE_1.log

printf "Installing the v12 binary...\n"
wget $STRIDE_CON_CHAIN_BINARY_URL -O $HOME/go/bin/$STRIDE_CHAIN_BINARY -q
chmod +x $HOME/go/bin/$STRIDE_CHAIN_BINARY

printf "Setting the revision height...\n"
let rev_height=$upgrade_height+3
echo "STRIDE_REV_HEIGHT=$rev_height" >> $GITHUB_ENV

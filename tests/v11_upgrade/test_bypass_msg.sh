#!/bin/bash
# Add bypass message type

if [ ! $VOTING_PERIOD ]
then
    VOTING_PERIOD=6
fi

echo "Testing withdraw-all-rewards transaction with 0 fees before adding it to the bypass message list..."
withdraw_rewards="$CHAIN_BINARY tx distribution withdraw-all-rewards --from $WALLET_1 -b block -y -o json --home $HOME_1"
echo $withdraw_rewards
tx_result=$($withdraw_rewards | jq -r '.code')
echo $tx_result
if [ $tx_result != "0" ]; then
    echo "Withdraw-all-rewards transaction failed: it is not in the bypass message list yet."
else
    echo "Withdraw-all-rewards transaction succeeded."
    exit 1
fi

echo "Submitting proposal to add withdraw-rewards message bypass to the globalfee module..."
proposal="$CHAIN_BINARY tx gov submit-proposal param-change tests/v11_upgrade/bypass_withdraw_msg.json --from $WALLET_1 --gas 200000 --fees 5000uatom -b block -y -o json --home $HOME_1"
echo $proposal
txhash=$($proposal | jq -r .txhash)
# Wait for the proposal to go on chain
sleep 6

# Get proposal ID from tx hash
proposal_id=$($CHAIN_BINARY --output json q tx $txhash --home $HOME_1 | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')
# Vote yes on the proposal
echo "Submitting the \"yes\" vote to proposal $proposal_id"
vote="$CHAIN_BINARY tx gov vote $proposal_id yes --from $WALLET_1 --fees 5000uatom --yes -b block --home $HOME_1"
echo $vote
$vote

# Wait for the voting period to be over
echo "Waiting for the voting period to end..."
sleep $VOTING_PERIOD

$CHAIN_BINARY q globalfee params -o json --home $HOME_1 > globalfee-params-withdraw-bypass.json
jq '.' globalfee-params-withdraw-bypass.json

echo "Testing withdraw-all-rewards transaction with 0 fees after adding it to the bypass message list..."
withdraw_rewards="$CHAIN_BINARY tx distribution withdraw-all-rewards --from $WALLET_1 -b block -y -o json --home $HOME_1"
echo $withdraw_rewards
tx_result=$($withdraw_rewards | jq -r '.code')
echo $tx_result
if [ $tx_result == "0" ]; then
    echo "Withdraw-all-rewards transaction succeeded: it is in the bypass message list now."
else
    echo "Withdraw-all-rewards transaction failed."
    exit 1
fi

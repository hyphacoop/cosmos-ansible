#!/bin/bash
# Add bypass message type

validator_address=$(jq -r '.address' ~/.gaia/validator.json)

withdraw_rewards="gaiad tx distribution withdraw-all-rewards --from $validator_address -b block -y -o json"
tx_result=$($withdraw_rewards | jq -r '.code')
echo $tx_result
if [ $tx_result == "13" ]; then
    echo "Withdraw-all-rewards transaction failed: it is not in the bypass message list yet."
else
    echo "Withdraw-all-rewards transaction succeeded."
    exit 1
fi

echo "Submitting proposal to add withdraw-rewards message bypass to the globalfee module..."
proposal="gaiad tx gov submit-proposal param-change tests/v11_upgrade/bypass_withdraw_msg.json --from $validator_address --gas 200000 --fees 500uatom -b block -y -o json"
echo $proposal
txhash=$($proposal | jq -r .txhash)
# Wait for the proposal to go on chain
sleep 6

# Get proposal ID from tx hash
proposal_id=$(gaiad --output json q tx $txhash | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')
# Vote yes on the proposal
echo "Submitting the \"yes\" vote to proposal $proposal_id"
vote="gaiad tx gov vote $proposal_id yes --from $validator_address --fees 500uatom --yes"
echo $vote
$vote

# Wait for the voting period to be over
echo "Waiting for the voting period to end..."
sleep 8

gaiad q globalfee params -o json > globalfee-params-withdraw-bypass.json

withdraw_rewards="gaiad tx distribution withdraw-all-rewards --from $validator_address -b block -y -o json"
tx_result=$($withdraw_rewards | jq -r '.code')
echo $tx_result
if [ $tx_result == "0" ]; then
    echo "Withdraw-all-rewards transaction succeeded: it is in the bypass message list now."
else
    echo "Withdraw-all-rewards transaction failed."
    exit 1
fi
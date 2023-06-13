#!/bin/bash
# Set max gas to 1,000

$CHAIN_BINARY q params subspace globalfee MaxTotalBypassMinFeeMsgGasUsage --home $HOME_1

echo "Submitting proposal to update the bypass max usage..."
proposal="$CHAIN_BINARY tx gov submit-proposal param-change tests/v11_upgrade/byass_max_gas_usage_proposal.json --from $WALLET_1 --gas auto --fees $BASE_FEES$DENOM -b block -y -o json --home $HOME_1"
echo $proposal
txhash=$($proposal | jq -r .txhash)
# Wait for the proposal to go on chain
sleep 6

# Get proposal ID from txhash
echo "Get proposal ID from txhash"
proposal_id=$($CHAIN_BINARY --output json q tx $txhash --home $HOME_1 | jq -r '.logs[].events[] | select(.type=="submit_proposal") | .attributes[] | select(.key=="proposal_id") | .value')

# Vote yes on the proposal
echo "Submitting the \"yes\" vote to proposal $proposal_id"
vote="$CHAIN_BINARY tx gov vote $proposal_id yes --from $WALLET_1 --gas auto --fees $BASE_FEES$DENOM -b block --yes --home $HOME_1"
echo $vote
$vote
sleep 6

# Wait for the voting period to be over
echo "Waiting for the voting period to end..."
sleep 6

# Query the globalfee params
$CHAIN_BINARY q globalfee params -o json --home $HOME_1 > globalfee-bypass-gas.json
jq '.' globalfee-bypass-gas.json

echo "Testing withdraw-all-rewards transaction with 0 fees after adding it to the bypass message list and lowering the max gas usage to 1,000..."
withdraw_rewards="$CHAIN_BINARY tx distribution withdraw-all-rewards --from $WALLET_1 -b block -y -o json --home $HOME_1"
tx_result=$($withdraw_rewards | jq -r '.code')
echo $tx_result
if [ $tx_result == "0" ]; then
    echo "Withdraw-all-rewards transaction succeeded: it is in the bypass message list now."
else
    echo "Withdraw-all-rewards transaction failed."
    exit 1
fi

#!/bin/bash
# Test transactions with a fresh state.

set +e
set -x 

check_code()
{
  txhash=$1
  code=$($CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq '.code')
  if [ $code -ne 0 ]; then
    echo "tx was unsuccessful."
    $CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq '.'
    exit 1
  fi
}

echo "Sending funds with tx bank send..."
$CHAIN_BINARY tx bank send $WALLET_1 $WALLET_2 $VAL_STAKE_STEP$DENOM --home $HOME_1 --from $MONIKER_1 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --chain-id $CHAIN_ID -y -o json -b block
#TXHASH=$($CHAIN_BINARY tx bank send $WALLET_1 $WALLET_2 $VAL_STAKE_STEP$DENOM --home $HOME_1 --from $MONIKER_1 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --chain-id $CHAIN_ID -y -o json -b block | jq '.txhash' | tr -d '"')
check_code $TXHASH
sleep 20

echo "Delegating funds from test account to validator..."
TXHASH=$($CHAIN_BINARY tx staking delegate $VALOPER_1 $VAL_STAKE$DENOM --home $HOME_1 --from $MONIKER_2 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --chain-id $CHAIN_ID -y -o json -b block | jq '.txhash' | tr -d '"')
check_code $TXHASH
sleep 20

# Wait for rewards to accumulate
echo "Waiting for rewards to accumulate"
sleep 20
echo "Withdrawing rewards for test account..."
starting_balance=$($CHAIN_BINARY q bank balances $WALLET_2 --home $HOME_1 -o json | jq -r '.balances[] | select(.denom=="uatom").amount')
echo "Starting balance: $starting_balance"
TXHASH=$($CHAIN_BINARY tx distribution withdraw-rewards $VALOPER_1 --home $HOME_1 --from $MONIKER_2 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $BASE_FEES$DENOM --chain-id $CHAIN_ID -y -o json -b block | jq '.txhash' | tr -d '"')
check_code $TXHASH
sleep 10

# Check the funds again
echo $($CHAIN_BINARY q bank balances $WALLET_2 --home $HOME_1 -o json)
$CHAIN_BINARY q bank balances $WALLET_2 --home $HOME_1
ending_balance=$($CHAIN_BINARY q bank balances $WALLET_2 --home $HOME_1 -o json | jq -r '.balances[] | select(.denom=="uatom").amount')
echo "Ending balance: $ending_balance"
delta=$[ $ending_balance - $starting_balance]
if [ $delta -gt 0 ]; then
    echo "$delta uatom were withdrawn successfully."
else
    echo "Rewards could not be withdrawn. Delta is: $delta"
    exit 1
fi

echo "Unbonding funds from test account to validator..."
TXHASH=$($CHAIN_BINARY tx staking unbond $VALOPER_1 $VAL_STAKE$DENOM --home $HOME_1 --from $MONIKER_1 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --fees $HIGH_FEES$DENOM --chain-id $CHAIN_ID -y -o json -b block | jq '.txhash' | tr -d '"')
check_code $TXHASH

#!/bin/bash
# Test transactions with a fresh state.

check_code()
{
  txhash=$1
  echo "Querying hash $txhash..."
  code=$($CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq '.code')
  if [ $code -ne 0 ]; then
    echo "tx was unsuccessful."
    $CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq '.'
    exit 1
  fi
}

echo "Sending funds with tx bank send..."
command="$CHAIN_BINARY tx bank send $WALLET_1 $WALLET_2 $VAL_STAKE_STEP$DENOM --home $HOME_1 --from $MONIKER_1 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --chain-id $CHAIN_ID -y -o json"
echo $command
TXHASH=$($command | jq -r '.txhash')
echo "Tx hash: $TXHASH"
sleep $(($COMMIT_TIMEOUT+2))
check_code $TXHASH

echo "Delegating funds from test account to validator..."
command="$CHAIN_BINARY tx staking delegate $VALOPER_1 $VAL_STAKE$DENOM --home $HOME_1 --from $MONIKER_1 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --chain-id $CHAIN_ID -y -o json"
echo $command
TXHASH=$($command | jq -r '.txhash')
echo "Tx hash: $TXHASH"
sleep $(($COMMIT_TIMEOUT+2))
check_code $TXHASH

# TXHASH=$($CHAIN_BINARY tx staking delegate $VALOPER_1 $VAL_STAKE$DENOM --home $HOME_1 --from $MONIKER_1 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --chain-id $CHAIN_ID -y -o json | jq -r '.txhash')
# check_code $TXHASH
# sleep $COMMIT_TIMEOUT
starting_balance=$($CHAIN_BINARY q bank balances $WALLET_1 --home $HOME_1 -o json | jq -r '.balances[] | select(.denom=="uatom").amount')
echo "Starting balance: $starting_balance"
echo "Waiting for rewards to accumulate..."
sleep 20
echo "Withdrawing rewards for test account..."
TXHASH=$($CHAIN_BINARY tx distribution withdraw-rewards $VALOPER_1 --home $HOME_1 --from $MONIKER_1 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --chain-id $CHAIN_ID -y -o json | jq -r '.txhash')
echo "Tx hash: $TXHASH"
sleep $(($COMMIT_TIMEOUT+2))
check_code $TXHASH

ending_balance=$($CHAIN_BINARY q bank balances $WALLET_1 --home $HOME_1 -o json | jq -r '.balances[] | select(.denom=="uatom").amount')
echo "Ending balance: $ending_balance"
delta=$[ $ending_balance - $starting_balance]
if [ $delta -gt 0 ]; then
    echo "$delta uatom were withdrawn successfully."
else
    echo "Rewards could not be withdrawn."
    exit 1
fi

# $CHAIN_BINARY q staking validators --home $HOME_1

echo "Unbonding funds from test account to validator..."
TXHASH=$($CHAIN_BINARY tx staking unbond $VALOPER_1 $VAL_STAKE$DENOM --home $HOME_1 --from $MONIKER_1 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --chain-id $CHAIN_ID -y -o json | jq -r '.txhash')
echo "Tx hash: $TXHASH"
sleep $(($COMMIT_TIMEOUT+2))
check_code $TXHASH

# $CHAIN_BINARY q staking validators --home $HOME_1
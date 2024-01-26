#!/bin/bash

# Test globalfee for different minimum_gas_prices scenarios
# by sending funds from WALLET_1 to WALLET_2.
# Node gas prices are set to 0.005uatom.

# 1. globalfee < node
# set globalfee = 0.002uatom
jq '.changes[0].value[0].amount = "0.003"' tests/major_fresh_upgrade/globalfee-params.json > globalfee-1.json
tests/param_change.sh globalfee-1.json
amount=$($CHAIN_BINARY q globalfee params -o json --home $HOME_1 | jq -r --arg DENOM "$DENOM" '.minimum_gas_prices[] | select(.denom == $DENOM).amount')
echo "globalfee minimum_gas_prices: $amount$DENOM"

echo "1-1: tx < globalfee < node: FAIL"
GAS_PRICE=0.002
command="$CHAIN_BINARY tx bank send $WALLET_1 $WALLET_1 1000$DENOM --from $WALLET_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --home $HOME_1 -o json -y"
txhash=$($command | jq -r .txhash)
sleep $(( $COMMIT_TIMEOUT*2 ))
txcode=$($CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq -r '.code')
echo "tx result code: $txcode"

if [[ -n "$txcode" ]]; then
  echo "Tx successful: FAIL"
  exit 1
else
  echo "Tx unsuccessful: PASS"
fi

echo "1-2: globalfee < tx < node: FAIL"
GAS_PRICE=0.004
command="$CHAIN_BINARY tx bank send $WALLET_1 $WALLET_1 1000$DENOM --from $WALLET_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --home $HOME_1 -o json -y"
txhash=$($command | jq -r .txhash)
sleep $(( $COMMIT_TIMEOUT*2 ))
txcode=$($CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq -r '.code')
echo "tx result code: $txcode"

if [[ -n "$txcode" ]]; then
  echo "Tx successful: FAIL"
  exit 1
else
  echo "Tx unsuccessful: PASS"
fi

echo "1-3: globalfee < node <= tx: PASS"
GAS_PRICE=0.005
command="$CHAIN_BINARY tx bank send $WALLET_1 $WALLET_1 1000$DENOM --from $WALLET_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --home $HOME_1 -o json -y"
txhash=$($command | jq -r .txhash)
sleep $(( $COMMIT_TIMEOUT*2 ))
txcode=$($CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq -r '.code')
echo "tx result code: $txcode"

if [ "$txcode" -ne "0" ]; then
  echo "Tx unsuccessful: FAIL"
  exit 1
else
  echo "Tx successful: PASS"
fi

# 2. set node < globalfee
# globalfee = 0.007uatom
jq '.changes[0].value[0].amount = "0.007"' tests/major_fresh_upgrade/globalfee-params.json > globalfee-1.json
tests/param_change.sh globalfee-1.json
amount=$($CHAIN_BINARY q globalfee params -o json --home $HOME_1 | jq -r --arg DENOM "$DENOM" '.minimum_gas_prices[] | select(.denom == $DENOM).amount')
echo "globalfee minimum_gas_prices: $amount$DENOM"

# 2-1 tx < node < globalfee: FAIL
echo "2-1: tx < node < globalfee: FAIL"
GAS_PRICE=0.004
command="$CHAIN_BINARY tx bank send $WALLET_1 $WALLET_1 1000$DENOM --from $WALLET_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --home $HOME_1 -o json -y"
txhash=$($command | jq -r .txhash)
sleep $(( $COMMIT_TIMEOUT*2 ))
txcode=$($CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq -r '.code')
echo "tx result code: $txcode"

if [[ -n "$txcode" ]]; then
  echo "Tx successful: FAIL"
  exit 1
else
  echo "Tx unsuccessful: PASS"
fi

echo "2-2: node < tx < globalfee: FAIL"
GAS_PRICE=0.006
command="$CHAIN_BINARY tx bank send $WALLET_1 $WALLET_1 1000$DENOM --from $WALLET_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --home $HOME_1 -o json -y"
txhash=$($command | jq -r .txhash)
sleep $(( $COMMIT_TIMEOUT*2 ))
txcode=$($CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq -r '.code')
echo "tx result code: $txcode"

if [[ -n "$txcode" ]]; then
  echo "Tx successful: FAIL"
  exit 1
else
  echo "Tx unsuccessful: PASS"
fi

echo "2-3: node < globalfee <= tx: PASS"
GAS_PRICE=0.007
command="$CHAIN_BINARY tx bank send $WALLET_1 $WALLET_1 1000$DENOM --from $WALLET_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM --home $HOME_1 -o json -y"
txhash=$($command | jq -r .txhash)
sleep $(( $COMMIT_TIMEOUT*2 ))
txcode=$($CHAIN_BINARY q tx $txhash -o json --home $HOME_1 | jq -r '.code')
echo "tx result code: $txcode"

if [ "$txcode" -ne "0" ]; then
  echo "Tx unsuccessful: FAIL"
  exit 1
else
  echo "Tx successful: PASS"
fi

echo "globalfee test done, set globalfee = node"
# set globalfee = 0.005uatom
GAS_PRICE=0.009
tests/param_change.sh tests/major_fresh_upgrade/globalfee-params.json
amount=$($CHAIN_BINARY q globalfee params -o json --home $HOME_1 | jq -r --arg DENOM "$DENOM" '.minimum_gas_prices[] | select(.denom == $DENOM).amount')
echo "globalfee minimum_gas_prices: $amount$DENOM"
GAS_PRICE=0.005

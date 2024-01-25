#!/bin/bash

# Test globalfee for different minimum_gas_prices scenarios
# by sending funds from WALLET_1 to WALLET_2.
# Node gas prices are set to 0.005uatom.

# 1. globalfee < node
# set globalfee = 0.001uatom
jq '.changes[0].value[0].amount = "0.001"' tests/major_fresh_upgrade/globalfee-params.json > globalfee-1.json
tests/param_change.sh globalfee-1.json
amount=$($CHAIN_BINARY q globalfee params -o json | jq -r --arg DENOM "$DENOM" '.minimum_gas_prices[] | select(.denom == $DENOM).amount')
echo "globalfee minimum_gas_prices: $amount$DENOM"

# 1-1 tx < globalfee < node: FAIL

# 1-2 globalfee < tx < node: FAIL

# 1-3 - globalfee < node < tx: PASS

# 2. set node < globalfee
# globalfee = 0.009uatom
jq '.changes[0].value[0].amount = "0.009"' tests/major_fresh_upgrade/globalfee-params.json > globalfee-1.json
tests/param_change.sh globalfee-1.json
amount=$($CHAIN_BINARY q globalfee params -o json | jq -r --arg DENOM "$DENOM" '.minimum_gas_prices[] | select(.denom == $DENOM).amount')
echo "globalfee minimum_gas_prices: $amount$DENOM"

# 2-1 tx < node < globalfee: FAIL

# 2-2 node < tx < globalfee: FAIL

# 2-3 node < globalfee < tx: PASS

# Finished, globalfee = node
# set globalfee = 0.005uatom
tests/param_change.sh tests/major_fresh_upgrade/globalfee-params.json
amount=$($CHAIN_BINARY q globalfee params -o json | jq -r --arg DENOM "$DENOM" '.minimum_gas_prices[] | select(.denom == $DENOM).amount')
echo "globalfee minimum_gas_prices: $amount$DENOM"

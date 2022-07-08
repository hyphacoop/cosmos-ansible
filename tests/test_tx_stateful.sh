#!/bin/bash

# Test transactions with a stateful state.
# This script assumes:
# - Tinkered genesis with validator-40 for valdator key
# - the bond denom is uatom
# - the home folder is ~/.gaia

check_code()
{
  txhash=$1
  code=$(gaiad q tx $txhash -o json | jq '.code')
  if [ $code -eq 0 ]
  then
    return 0
  else
    return 1
  fi
}

# Add gaiad to PATH
export PATH="$PATH:~/.gaia/cosmovisor/current/bin"

# Recover validator self-delegation and operator addresses
val_self_del=$(jq -r '.address' ~/.gaia/validator.json)
val1=$(echo $(gaiad q staking delegations $val_self_del -o json) | jq -r '.delegation_responses[0].delegation.validator_address')
echo "validator has self-delegation address $val_self_del."
echo "validator has operator address $val1."

# Create test account
echo $(gaiad keys add test-account --keyring-backend test --output json 2>&1) > test_account.json
test_account=$(jq -r '.address' ./test_account.json)
echo "test-account has address $test_account."

# Test tx send
echo "Sending funds from validator to test account..."
TXHASH=$(gaiad tx bank send $val_self_del $test_account 10000uatom --from $val_self_del --keyring-backend test --fees 500uatom --chain-id local-testnet -y -o json | jq '.txhash' | tr -d '"')
echo $TXHASH
echo "Waiting for transaction to go on chain..."
sleep 6
check_code $TXHASH

# Test delegation
echo "Delgating funds from test account to validator..."
# Delegate from test-account to validator
TXHASH=$(gaiad tx staking delegate $val1 5000uatom --from test-account --keyring-backend test --fees 500uatom --chain-id local-testnet -y -o json | jq '.txhash' | tr -d '"')
echo "Waiting for transaction to go on chain..."
sleep 12
check_code $TXHASH

# Test withdrawing rewards
starting_balance=$(gaiad q bank balances $test_account -o json | jq -r '.balances[0].amount')
balance_denom=$(gaiad q bank balances $test_account -o json | jq -r '.balances[0].denom')

echo "Withdrawing rewards for test account..."
TXHASH=$(gaiad tx distribution withdraw-all-rewards --from $test_account --keyring-backend test --fees 500uatom --chain-id local-testnet -y -o json | jq '.txhash' | tr -d '"')
# Wait for rewards to accumulate
echo "Waiting for transaction to go on chain..."
sleep 30
check_code $TXHASH

# Check the test-account funds
ending_balance=$(gaiad q bank balances $test_account -o json | jq -r '.balances[0].amount')
delta=$[ $ending_balance - $starting_balance]
if [ $delta -gt 0 ]
then
    echo "$delta$balance_denom were withdrawn successfully."
else
    echo "Rewards could not be withdrawn."
    exit 1
fi

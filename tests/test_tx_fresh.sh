#!/bin/bash

# Test transactions with a fresh state.
# This script assumes:
# - a faucet and validator have been created as part of the play
# - the bond denom is stake
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

# Recover faucet address
faucet=$(jq -r '.address' ~/.gaia/faucet.json)
echo "faucet has address $faucet."

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
echo "Sending funds from faucet to test account..."
TXHASH=$(gaiad tx bank send $faucet $test_account 5000100stake --from $faucet --keyring-backend test --fees 1stake --chain-id my-testnet -y -o json | jq '.txhash' | tr -d '"')
echo $TXHASH
echo "Waiting for transaction to go on chain..."
sleep 6
check_code $TXHASH

# Test delegation
echo "Delgating funds from test account to validator..."
# Delegate from test-account to validator
TXHASH=$(gaiad tx staking delegate $val1 4000000stake --from test-account --keyring-backend test --fees 1stake --chain-id my-testnet -y -o json | jq '.txhash' | tr -d '"')
echo "Waiting for transaction to go on chain..."
sleep 12
check_code $TXHASH

# Test withdrawing rewards
starting_balance=$(gaiad q bank balances $test_account -o json | jq -r '.balances[0].amount')
balance_denom=$(gaiad q bank balances $test_account -o json | jq -r '.balances[0].denom')

echo "Withdrawing rewards for test account..."
TXHASH=$(gaiad tx distribution withdraw-all-rewards --from $test_account --keyring-backend test --fees 1stake --chain-id my-testnet -y -o json | jq '.txhash' | tr -d '"')
# Wait for rewards to accumulate
echo "Waiting for transaction to go on chain..."
sleep 6
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

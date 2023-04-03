#!/bin/bash

host=$1
port=$2
NODE_ADDRESS=http://$host:$port

TEST_ACCOUNT="cosmos1r5v5srda7xfth3hn2s26txvrcrntldjumt8mhl"
VAL_ACCOUNT="cosmosvaloper1arjwkww79m65csulawqngr7ngs4uqu5hr3frxw"
DEL_ACCOUNT="cosmos1arjwkww79m65csulawqngr7ngs4uqu5hx9ak2a"
DENOM="uatom"
PROPOSAL_ID="1"
AUTH_ACCOUNTS="$NODE_ADDRESS/cosmos/auth/v1beta1/accounts"
BANK_BALANCES="$NODE_ADDRESS/cosmos/bank/v1beta1/balances/$TEST_ACCOUNT"
BANK_DENOMS_METADATA="$NODE_ADDRESS/cosmos/bank/v1beta1/denoms_metadata"
BANK_SUPPLY="$NODE_ADDRESS/cosmos/bank/v1beta1/supply"
DIST_SLASHES="$NODE_ADDRESS/cosmos/distribution/v1beta1/validators/$VAL_ACCOUNT/slashes"
EVIDENCE="$NODE_ADDRESS/cosmos/evidence/v1beta1/evidence"
GOV_PROPOSALS="$NODE_ADDRESS/cosmos/gov/v1beta1/proposals"
GOV_DEPOSITS="$NODE_ADDRESS/cosmos/gov/v1beta1/proposals/$PROPOSAL_ID/deposits"
GOV_VOTES="$NODE_ADDRESS/cosmos/gov/v1beta1/proposals/$PROPOSAL_ID/votes"
SLASH_SIGNING_INFOS="$NODE_ADDRESS/cosmos/slashing/v1beta1/signing_infos"
STAKING_DELEGATIONS="$NODE_ADDRESS/cosmos/staking/v1beta1/delegations/$TEST_ACCOUNT"
STAKING_REDELEGATIONS="$NODE_ADDRESS/cosmos/staking/v1beta1/delegators/$TEST_ACCOUNT/redelegations"
STAKING_UNBONDING="$NODE_ADDRESS/cosmos/staking/v1beta1/delegators/$TEST_ACCOUNT/unbonding_delegations"
STAKING_DEL_VALIDATORS="$NODE_ADDRESS/cosmos/staking/v1beta1/delegators/$TEST_ACCOUNT/validators"
STAKING_VALIDATORS="$NODE_ADDRESS/cosmos/staking/v1beta1/validators"
STAKING_VAL_DELEGATIONS="$NODE_ADDRESS/cosmos/staking/v1beta1/validators/$VAL_ACCOUNT/delegations"
STAKING_VAL_UNBONDING="$NODE_ADDRESS/cosmos/staking/v1beta1/validators/$VAL_ACCOUNT/unbonding_delegations"
TM_VALIDATORSETS="$NODE_ADDRESS/cosmos/base/tendermint/v1beta1/validatorsets/latest"

response_failed()
{
    printf "Endpoint failed!\n$1"
    exit 1
}

echo "Testing API endpoints..."

echo "> $AUTH_ACCOUNTS"
curl $AUTH_ACCOUNTS
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $AUTH_ACCOUNTS | jq -r '. | keys[0]')
echo "$RESPONSE"
if [ "$RESPONSE" != "accounts" ]; then
    response_failed $RESPONSE
fi

echo "> $BANK_BALANCES"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $BANK_BALANCES | jq -r '. | keys[0]')
if [ "$RESPONSE" != "balances" ]; then
    response_failed $RESPONSE
fi

echo "> $BANK_DENOMS_METADATA"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $BANK_DENOMS_METADATA | jq -r '. | keys[0]')
if [ "$RESPONSE" != "metadatas" ]; then
    response_failed $RESPONSE
fi

echo "> $BANK_SUPPLY"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $BANK_SUPPLY | jq -r '. | keys[-1]')
if [ "$RESPONSE" != "supply" ]; then
    response_failed $RESPONSE
fi

echo "> $DIST_SLASHES"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $DIST_SLASHES | jq -r '. | keys[1]')
if [ "$RESPONSE" != "slashes" ]; then
    response_failed $RESPONSE
fi

echo "> $EVIDENCE"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $EVIDENCE | jq -r '. | keys[0]')
if [ "$RESPONSE" != "evidence" ]; then
    response_failed $RESPONSE
fi

echo "> $GOV_PROPOSALS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $GOV_PROPOSALS | jq -r '. | keys[-1]')
if [ "$RESPONSE" != "proposals" ]; then
    response_failed $RESPONSE
fi

echo "> $GOV_DEPOSITS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $GOV_DEPOSITS | jq -r '. | keys[0]')
if [ "$RESPONSE" != "deposits" ]; then
    response_failed $RESPONSE
fi

echo "> $GOV_VOTES"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $GOV_VOTES | jq -r '. | keys[-1]')
if [ "$RESPONSE" != "votes" ]; then
    response_failed $RESPONSE
fi

echo "> $SLASH_SIGNING_INFOS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $SLASH_SIGNING_INFOS | jq -r '. | keys[0]')
if [ "$RESPONSE" != "info" ]; then
    response_failed $RESPONSE
fi

echo "> $STAKING_DELEGATIONS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $STAKING_DELEGATIONS | jq -r '. | keys[0]')
if [ "$RESPONSE" != "delegation_responses" ]; then
    response_failed $RESPONSE
fi

echo "> $STAKING_REDELEGATIONS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $STAKING_REDELEGATIONS | jq -r '. | keys[-1]')
if [ "$RESPONSE" != "redelegation_responses" ]; then
    response_failed $RESPONSE
fi

echo "> $STAKING_UNBONDING"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $STAKING_UNBONDING | jq -r '. | keys[-1]')
if [ "$RESPONSE" != "unbonding_responses" ]; then
    response_failed $RESPONSE
fi

echo "> $STAKING_DEL_VALIDATORS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $STAKING_DEL_VALIDATORS | jq -r '. | keys[-1]')
if [ "$RESPONSE" != "validators" ]; then
    response_failed $RESPONSE
fi

echo "> $STAKING_VALIDATORS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $STAKING_VALIDATORS | jq -r '. | keys[-1]')
if [ "$RESPONSE" != "validators" ]; then
    response_failed $RESPONSE
fi

echo "> $STAKING_VAL_DELEGATIONS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $STAKING_VAL_DELEGATIONS | jq -r '. | keys[0]')
if [ "$RESPONSE" != "delegation_responses" ]; then
    response_failed $RESPONSE
fi

echo "> $STAKING_VAL_UNBONDING"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $STAKING_VAL_UNBONDING | jq -r '. | keys[-1]')
if [ "$RESPONSE" != "unbonding_responses" ]; then
    response_failed $RESPONSE
fi

echo "> $TM_VALIDATORSETS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $TM_VALIDATORSETS | jq -r '. | keys[-1]')
if [ "$RESPONSE" != "validators" ]; then
    response_failed $RESPONSE
fi

printf "API endpoints available\n"

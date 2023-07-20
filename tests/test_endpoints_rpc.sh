#!/bin/bash

host=$1
port=$2
NODE_ADDRESS=http://$host:$port

TEST_ACCOUNT="cosmos1r5v5srda7xfth3hn2s26txvrcrntldjumt8mhl"
VAL_ACCOUNT="cosmosvaloper1arjwkww79m65csulawqngr7ngs4uqu5hr3frxw"
DEL_ACCOUNT="cosmos1arjwkww79m65csulawqngr7ngs4uqu5hx9ak2a"
DENOM="uatom"
PROPOSAL_ID="1"
ABCI_INFO="$NODE_ADDRESS/abci_info"
BLOCK="$NODE_ADDRESS/block"
BLOCK_RESULTS="$NODE_ADDRESS/block_results"
BLOCKCHAIN="$NODE_ADDRESS/blockchain"
COMMIT="$NODE_ADDRESS/commit"
CONSENSUS_PARAMS="$NODE_ADDRESS/consensus_params"
CONSENSUS_STATE="$NODE_ADDRESS/consensus_state"
DUMP_CONSENSUS_STATE="$NODE_ADDRESS/dump_consensus_state"
# GENESIS="$NODE_ADDRESS/genesis" # not tested: will fail if the genesis file is too large
GENESIS_CHUNKED="$NODE_ADDRESS/genesis_chunked"
NET_INFO="$NODE_ADDRESS/net_info"
NUM_UNCONFIRMED_TXS="$NODE_ADDRESS/num_unconfirmed_txs"
UNCONFIRMED_TXS="$NODE_ADDRESS/unconfirmed_txs"
STATUS="$NODE_ADDRESS/status"
VALIDATORS="$NODE_ADDRESS/validators"

response_failed()
{
    printf "Endpoint failed!\n"
    echo $1
    exit 1
}

echo "Testing RPC endpoints..."

echo "> $ABCI_INFO"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $ABCI_INFO | jq -r '.result | keys[0]')
if [ "$RESPONSE" != "response" ]; then
    response_failed $RESPONSE
fi

echo "> $BLOCK"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $BLOCK | jq -r '.result | keys[0]')
if [ "$RESPONSE" != "block" ]; then
    response_failed $RESPONSE
fi

echo "> $BLOCK_RESULTS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $BLOCK_RESULTS | jq -r '.result | keys[0]')
if [ "$RESPONSE" != "begin_block_events" ]; then
    response_failed $RESPONSE
fi

echo "> $BLOCKCHAIN"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $BLOCKCHAIN | jq -r '.result | keys[0]')
if [ "$RESPONSE" != "block_metas" ]; then
    response_failed $RESPONSE
fi

echo "> $COMMIT"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $COMMIT | jq -r '.result | keys[-1]')
if [ "$RESPONSE" != "signed_header" ]; then
    response_failed $RESPONSE
fi

echo "> $CONSENSUS_PARAMS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $CONSENSUS_PARAMS | jq -r '.result | keys[-1]')
if [ "$RESPONSE" != "consensus_params" ]; then
    response_failed $RESPONSE
fi

echo "> $CONSENSUS_STATE"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $CONSENSUS_STATE | jq -r '.result | keys[-1]')
if [ "$RESPONSE" != "round_state" ]; then
    response_failed $RESPONSE
fi

echo "> $DUMP_CONSENSUS_STATE"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $DUMP_CONSENSUS_STATE | jq -r '.result | keys[-1]')
if [ "$RESPONSE" != "round_state" ]; then
    response_failed $RESPONSE
fi

echo "> $GENESIS_CHUNKED"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $GENESIS_CHUNKED | jq -r '.result | keys[0]')
if [ "$RESPONSE" != "chunk" ]; then
    response_failed $RESPONSE
fi

echo "> $NET_INFO"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $NET_INFO | jq -r '.result | keys[-1]')
if [ "$RESPONSE" != "peers" ]; then
    response_failed $RESPONSE
fi

echo "> $NUM_UNCONFIRMED_TXS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $NUM_UNCONFIRMED_TXS | jq -r '.result | keys[0]')
if [ "$RESPONSE" != "n_txs" ]; then
    response_failed $RESPONSE
fi

echo "> $UNCONFIRMED_TXS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $UNCONFIRMED_TXS | jq -r '.result | keys[0]')
if [ "$RESPONSE" != "n_txs" ]; then
    response_failed $RESPONSE
fi

echo "> $STATUS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $STATUS | jq -r '.result | keys[0]')
if [ "$RESPONSE" != "node_info" ]; then
    response_failed $RESPONSE
fi

echo "> $VALIDATORS"
RESPONSE=$(curl --retry 10 --retry-delay 5 --retry-connrefused -s $VALIDATORS | jq -r '.result | keys[-1]')
if [ "$RESPONSE" != "validators" ]; then
    response_failed $RESPONSE
fi

printf "RPC endpoints available\n"

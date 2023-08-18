#!/bin/bash
# ICA delegation failure cases

source tests/process_tx.sh

validator_breach=100000000
global_breach=140000000

starting_balance=$($CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq -r '.balances[] | select(.denom=="uatom").amount')
$CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'

echo "** LIQUID STAKING PROVIDER FAILURE CASES> 1: ICA DELEGATION WITHOUT VALIDATOR BOND **"

    jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > delegate-fail-1.json
    message=$(jq -r --arg ADDRESS "$VALOPER_1" '.validator_address = $ADDRESS' delegate-fail-1.json)
    echo "Generating packet JSON..."
    $STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$message" > delegate_packet.json
    echo "Sending tx staking delegate to host chain..."
    submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
    echo "Waiting for delegation to go on-chain..."
    sleep $(($COMMIT_TIMEOUT*4))
    $CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
    
    balance=$($CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq -r '.balances[] | select(.denom=="uatom").amount')
    if [[ $balance -eq $starting_balance ]]; then
        echo "Failure case 1 success: balance remains unchanged"
    else
        echo "Failure case 1 failure: balance has changed"
        exit 1
    fi

echo "** LIQUID STAKING PROVIDER FAILURE CASES> 2: ICA DELEGATION BREACHES VALIDATOR LIQUID STAKING CAP **"

    jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > delegate-val-breach-1.json
    jq -r --arg ADDRESS "$VALOPER_2" '.validator_address = $ADDRESS' delegate-val-breach-1.json > delegate-val-breach-2.json
    jq -r --arg AMOUNT "$validator_breach" '.amount.amount = $AMOUNT' delegate-val-breach-2.json > delegate-val-breach-3.json
    cp delegate-val-breach-3.json val-breach.json

    echo "Generating packet JSON..."
    $STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat val-breach.json)" > delegate_packet.json
    echo "Sending tx staking delegate to host chain..."
    submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
    echo "Waiting for delegation to go on-chain..."
    sleep $(($COMMIT_TIMEOUT*4))

    $CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
    balance=$($CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq -r '.balances[] | select(.denom=="uatom").amount')
    if [[ $balance -eq $starting_balance ]]; then
        echo "Failure case 2 success: balance remains unchanged"
    else
        echo "Failure case 2 failure: balance has changed"
        exit 1
    fi

echo "** LIQUID STAKING PROVIDER FAILURE CASES> 3: ICA DELEGATION BREACHES GLOBAL LIQUID STAKING CAP **"

    jq -r --arg ADDRESS "$ICA_ADDRESS" '.delegator_address = $ADDRESS' tests/v12_upgrade/msg-delegate.json > delegate-global-breach-1.json
    jq -r --arg ADDRESS "$VALOPER_1" '.validator_address = $ADDRESS' delegate-global-breach-1.json > delegate-global-breach-2.json
    jq -r --arg AMOUNT "$global_breach" '.amount.amount = $AMOUNT' delegate-global-breach-2.json > delegate-global-breach-3.json
    cat delegate-global-breach-3.json
    cp delegate-global-breach-3.json global-breach.json
    echo "Generating packet JSON..."
    $STRIDE_CHAIN_BINARY tx interchain-accounts host generate-packet-data "$(cat global-breach.json)" > delegate_packet.json
    echo "Sending tx staking delegate to host chain..."
    submit_ibc_tx "tx interchain-accounts controller send-tx connection-0 delegate_packet.json --from $STRIDE_WALLET_1 --chain-id $STRIDE_CHAIN_ID --gas auto --fees $BASE_FEES$STRIDE_DENOM --gas-adjustment $GAS_ADJUSTMENT -y -o json" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
    echo "Waiting for delegation to go on-chain..."
    sleep $(($COMMIT_TIMEOUT*4))

    $CHAIN_BINARY q staking validators -o json --home $HOME_1 | jq '.'
    balance=$($CHAIN_BINARY q bank balances $ICA_ADDRESS -o json --home $HOME_1 | jq -r '.balances[] | select(.denom=="uatom").amount')
    if [[ $balance -eq $starting_balance ]]; then
        echo "Failure case 3 success: balance remains unchanged"
    else
        echo "Failure case 3 failure: balance has changed"
        exit 1
    fi

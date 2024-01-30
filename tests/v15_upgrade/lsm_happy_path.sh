#!/bin/bash
# set -x
source tests/process_tx.sh

delegation=100000000
tokenize=50000000
bank_send_amount=20000000
ibc_transfer_amount=10000000
liquid_1_redeem=20000000
tokenized_denom=$VALOPER_1/$VALOPER_TOKENIZATION

# $CHAIN_BINARY keys add happy_bonding --home $HOME_1
# $CHAIN_BINARY keys add happy_liquid_1 --home $HOME_1
# $CHAIN_BINARY keys add happy_liquid_2 --home $HOME_1
# $CHAIN_BINARY keys add happy_liquid_3 --home $HOME_1
# $CHAIN_BINARY keys add happy_owner --home $HOME_1

$CHAIN_BINARY keys list --home $HOME_1 --output json

happy_bonding=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_bonding").address')
happy_liquid_1=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_liquid_1").address')
happy_liquid_2=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_liquid_2").address')
happy_liquid_3=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_liquid_3").address')
happy_owner=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_owner").address')

# echo "Funding bonding and tokenizing accounts..."
# submit_tx "tx bank send $WALLET_1 $happy_bonding  200000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
# submit_tx "tx bank send $WALLET_1 $happy_liquid_1 200000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
# submit_tx "tx bank send $WALLET_1 $happy_liquid_2 200000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
# submit_tx "tx bank send $WALLET_1 $happy_liquid_3 200000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
# submit_tx "tx bank send $WALLET_1 $happy_owner 10000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1

echo "** HAPPY PATH> STEP 1: VALIDATOR BOND **"

    delegator_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
    validator_bond_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')

    echo "Delegating with happy_bonding..."
    # tests/v12_upgrade/log_lsm_data.sh happy pre-delegate-1 $happy_bonding $delegation
    $CHAIN_BINARY q staking validator cosmosvaloper1r5v5srda7xfth3hn2s26txvrcrntldju7lnwmv --home $HOME_1
    submit_tx "tx staking delegate $VALOPER_1 $delegation$DENOM --from $happy_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-delegate-1 $happy_bonding $delegation
    $CHAIN_BINARY q staking validator cosmosvaloper1r5v5srda7xfth3hn2s26txvrcrntldju7lnwmv --home $HOME_1

    delegator_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
    shares_diff=$((${delegator_shares_2%.*}-${delegator_shares_1%.*})) # remove decimal portion
    echo "Delegator shares difference: $shares_diff"
    if [[ $shares_diff -ne $delegation ]]; then
        echo "Delegation unsuccessful."
        exit 1
    fi

    echo "Validator bond with happy_bonding..."
    # tests/v12_upgrade/log_lsm_data.sh happy pre-bond-1 $happy_bonding -
    $CHAIN_BINARY q staking validator cosmosvaloper1r5v5srda7xfth3hn2s26txvrcrntldju7lnwmv --home $HOME_1
    submit_tx "tx staking validator-bond $VALOPER_1 --from $happy_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --gas-prices $GAS_PRICE$DENOM" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-bond-1 $happy_bonding -
    $CHAIN_BINARY q staking validator cosmosvaloper1r5v5srda7xfth3hn2s26txvrcrntldju7lnwmv --home $HOME_1

    validator_bond_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    bond_shares_diff=$((${validator_bond_shares_2%.*}-${validator_bond_shares_1%.*})) # remove decimal portion
    echo "Bond shares difference: $bond_shares_diff"
    if [[ $shares_diff -ne $delegation  ]]; then
        echo "Validator bond unsuccessful."
        exit 1
    fi

echo "** HAPPY PATH> STEP 2: TOKENIZE **"

    delegator_shares_1=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')

    echo "Delegating with $happy_liquid_1..."
    # tests/v12_upgrade/log_lsm_data.sh happy pre-delegate-2 $happy_liquid_1 $delegation
    $CHAIN_BINARY q staking validator cosmosvaloper1r5v5srda7xfth3hn2s26txvrcrntldju7lnwmv --home $HOME_1
    submit_tx "tx staking delegate $VALOPER_1 $delegation$DENOM --from $happy_liquid_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-delegate-2 $happy_liquid_1 $delegation
    $CHAIN_BINARY q staking validator cosmosvaloper1r5v5srda7xfth3hn2s26txvrcrntldju7lnwmv --home $HOME_1

    delegator_shares_2=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.delegator_shares')
    shares_diff=$((${delegator_shares_2%.*}-${delegator_shares_1%.*})) # remove decimal portion
    echo "Delegator shares difference: $shares_diff"
    if [[ $shares_diff -ne $delegation ]]; then
        echo "Delegation unsuccessful."
        exit 1
    fi

    liquid_shares_pre_tokenize=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.liquid_shares')
    echo "Tokenizing shares with $happy_liquid_1..."
    # tests/v12_upgrade/log_lsm_data.sh happy pre-tokenize-1 $happy_liquid_1 $tokenize
    submit_tx "tx staking tokenize-share $VALOPER_1 $tokenize$DENOM $happy_liquid_1 --from $happy_liquid_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-tokenize-1 $happy_liquid_1 $tokenize

    liquid_shares_post_tokenize=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.liquid_shares')
    liquid_shares_diff=$(echo "$liquid_shares_post_tokenize-$liquid_shares_pre_tokenize" | bc -l)
    liquid_shares_diff=${liquid_shares_diff%.*}
    
    if [[ $liquid_shares_diff -eq $tokenize  ]]; then
        echo "Tokenization successful."
    elif [[ $(($liquid_shares_diff-$tokenize)) -eq 1 ]]; then
        echo "Tokenization successful: liquid shares increase off by 1"
    elif [[ $(($tokenize-$liquid_shares_diff)) -eq 1 ]]; then
        echo "Tokenization successful: liquid shares increase off by 1"
    else
        echo "Tokenization unsuccessful: unexpected increase in liquid shares amount ($liquid_shares_diff != $tokenize)"
        exit 1 
    fi

    $CHAIN_BINARY q bank balances $happy_liquid_1 --home $HOME_1
    liquid_balance=$($CHAIN_BINARY q bank balances $happy_liquid_1 --home $HOME_1 -o json | jq -r --arg DENOM "$tokenized_denom" '.balances[] | select(.denom==$DENOM).amount')
    echo "Liquid balance: ${liquid_balance%.*}"
    if [[ ${liquid_balance%.*} -ne $tokenize ]]; then
        echo "Tokenize unsuccessful: unexpected liquid token balance"
        exit 1
    fi

echo "** HAPPY PATH> STEP 3: TRANSFER OWNERSHIP **"

    record_id=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.id')
    owner=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.owner')
    echo "$owner owns record $record_id."

    echo "Transferring token ownership record to new_owner..."
    # tests/v12_upgrade/log_lsm_data.sh happy pre-transfer-1 $happy_owner -
    submit_tx "tx staking transfer-tokenize-share-record $record_id $happy_owner --from $owner --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-transfer-1 $happy_owner -
    owner=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.owner')
    echo "$owner owns record $record_id."
    if [[ "$owner" == "$happy_owner" ]]; then
        echo "Token ownership transfer succeeded."
    else
        echo "Token ownership transfer failed."
    fi

    echo "Transferring token ownership record back to happy_liquid_1..."
    # tests/v12_upgrade/log_lsm_data.sh happy pre-transfer-2 $owner -
    submit_tx "tx staking transfer-tokenize-share-record $record_id $happy_liquid_1 --from $owner --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-transfer-2 $owner -
    owner=$($CHAIN_BINARY q staking tokenize-share-record-by-denom $tokenized_denom --home $HOME_1 -o json | jq -r '.record.owner')
    echo "$owner owns record $record_id."
    if [[ "$owner" == "$happy_liquid_1" ]]; then
        echo "Token ownership transfer succeeded."
    else
        echo "Token ownership transfer failed."
    fi

echo "** HAPPY PATH> STEP 4: TRANSFER TOKENS  **"

    happy_liquid_1_delegations_1=$($CHAIN_BINARY q staking delegations $happy_liquid_1 --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).delegation.shares')
    echo "happy_liquid_1 delegations: $happy_liquid_1_delegations_1"

    echo "Sending tokens from happy_liquid_1 to happy_liquid_2 via bank send..."
    submit_tx "tx bank send $happy_liquid_1 $happy_liquid_2 $bank_send_amount$tokenized_denom --from $happy_liquid_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1

    echo "Sending tokens from happy_liquid_1 to STRIDE_WALLET_LIQUID via ibc transfer..."
    submit_ibc_tx "tx ibc-transfer transfer transfer $IBC_CHANNEL $STRIDE_WALLET_LIQUID $ibc_transfer_amount$tokenized_denom --from $happy_liquid_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    sleep $(($COMMIT_TIMEOUT*20))
    $STRIDE_CHAIN_BINARY q bank balances $STRIDE_WALLET_LIQUID --home $STRIDE_HOME_1 -o json | jq '.'
    journalctl -u $RELAYER | tail -n 50
    ibc_denom=ibc/$($STRIDE_CHAIN_BINARY q ibc-transfer denom-hash transfer/channel-1/$tokenized_denom --home $STRIDE_HOME_1 -o json | jq -r '.hash')
    ibc_balance=$($STRIDE_CHAIN_BINARY q bank balances $STRIDE_WALLET_LIQUID --home $STRIDE_HOME_1 -o json | jq -r --arg DENOM "$ibc_denom" '.balances[] | select(.denom==$DENOM).amount')
    echo "IBC-wrapped liquid token balance: $ibc_balance$ibc_denom"
    if [[ $ibc_balance -ne $ibc_transfer_amount ]]; then
        echo "Tokenize unsuccessful: unexpected ibc-wrapped liquid token balance"
        exit 1
    fi

echo "** HAPPY PATH> STEP 5: REDEEM TOKENS **"
    echo "Redeeming tokens from happy_liquid_1..."
    # tests/v12_upgrade/log_lsm_data.sh happy pre-redeem-1 $happy_liquid_1 $liquid_1_redeem
    $CHAIN_BINARY q bank balances $happy_liquid_1 --home $HOME_1 -o json | jq '.'
    submit_tx "tx staking redeem-tokens $liquid_1_redeem$tokenized_denom --from $happy_liquid_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-redeem-1 $happy_liquid_1 $liquid_1_redeem
    sleep $(($COMMIT_TIMEOUT*10))
    echo "Redeeming tokens from happy_liquid_2..."
    # tests/v12_upgrade/log_lsm_data.sh happy pre-redeem-2 $happy_liquid_2 $bank_send_amount
    submit_tx "tx staking redeem-tokens $bank_send_amount$tokenized_denom --from $happy_liquid_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-redeem-2 $happy_liquid_2 $bank_send_amount
    sleep $(($COMMIT_TIMEOUT*10))

    echo "Sending $ibc_denom tokens from STRIDE_WALLET_LIQUID to $CHAIN_ID chain for redeem operation..."
    $CHAIN_BINARY q bank balances $happy_liquid_3 --home $HOME_1
    submit_ibc_tx "tx ibc-transfer transfer transfer channel-1 $happy_liquid_3 $ibc_transfer_amount$ibc_denom --from $STRIDE_WALLET_LIQUID -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$STRIDE_DENOM -y" $STRIDE_CHAIN_BINARY $STRIDE_HOME_1
    sleep 20
    $CHAIN_BINARY q bank balances $happy_liquid_3 --home $HOME_1
    echo "***RELAYER DATA***"
    journalctl -u $RELAYER | tail -n 100
    echo "***RELAYER DATA***"
    echo "Redeeming tokens from happy_liquid_3..."
    $CHAIN_BINARY q tendermint-validator-set --home $HOME_1
    $CHAIN_BINARY q tendermint-validator-set --home $STRIDE_HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy pre-redeem-3 $happy_liquid_3 $ibc_transfer_amount
    submit_tx "tx staking redeem-tokens $ibc_transfer_amount$tokenized_denom --from $happy_liquid_3 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-redeem-3 $happy_liquid_3 $ibc_transfer_amount

    happy_liquid_1_delegations_2=$($CHAIN_BINARY q staking delegations $happy_liquid_1 --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).delegation.shares')
    happy_liquid_1_delegations_diff=$((${happy_liquid_1_delegations_2%.*}-${happy_liquid_1_delegations_1%.*}))
    happy_liquid_2_delegations=$($CHAIN_BINARY q staking delegations $happy_liquid_2 --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).delegation.shares')
    happy_liquid_3_delegations=$($CHAIN_BINARY q staking delegations $happy_liquid_3 --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).delegation.shares')

    happy_liquid_1_delegation_balance=$($CHAIN_BINARY q staking delegations $happy_liquid_1 --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).balance.amount')
    happy_liquid_2_delegation_balance=$($CHAIN_BINARY q staking delegations $happy_liquid_2 --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).balance.amount')
    happy_liquid_3_delegation_balance=$($CHAIN_BINARY q staking delegations $happy_liquid_3 --home $HOME_1 -o json | jq -r --arg ADDRESS "$VALOPER_1" '.delegation_responses[] | select(.delegation.validator_address==$ADDRESS).balance.amount')

    echo "happy_liquid_1 delegation shares increase: $happy_liquid_1_delegations_diff"
    if [[ $happy_liquid_1_delegations_diff -ne 20000000 ]]; then
        echo "Redeem unsuccessful: unexpected delegation shares for happy_liquid_1"
        exit 1
    fi

    echo "happy_liquid_1 delegation balance: $happy_liquid_1_delegation_balance"
    if [[ $happy_liquid_1_delegation_balance -ne 70000000 ]]; then
        echo "Redeem unsuccessful: unexpected delegation balance for happy_liquid_1"
        exit 1
    fi

    echo "happy_liquid_2 delegation shares: ${happy_liquid_2_delegations%.*}"
    if [[ ${happy_liquid_2_delegations%.*} -ne $bank_send_amount ]]; then
        echo "Redeem unsuccessful: unexpected delegation shares for happy_liquid_2"
        exit 1
    fi

    echo "happy_liquid_2 delegation balance: $happy_liquid_2_delegation_balance"
    if [[ $happy_liquid_2_delegation_balance -ne $bank_send_amount ]]; then
        echo "Redeem unsuccessful: unexpected delegation balance for happy_liquid_2"
        exit 1
    fi

    echo "happy_liquid_3 delegation shares: ${happy_liquid_3_delegations%.*}"
    if [[ ${happy_liquid_3_delegations%.*} -ne $ibc_transfer_amount ]]; then
        echo "Redeem unsuccessful: unexpected delegation shares for happy_liquid_3"
        exit 1
    fi

    echo "happy_liquid_3 delegation balance: $happy_liquid_2_delegation_balance"
    if [[ $happy_liquid_3_delegation_balance -ne $ibc_transfer_amount ]]; then
        echo "Redeem unsuccessful: unexpected delegation balance for happy_liquid_3"
        exit 1
    fi

echo "** HAPPY PATH> CLEANUP **"

    echo "Validator unbond from happy_bonding"
    # tests/v12_upgrade/log_lsm_data.sh happy pre-unbond-1 $happy_bonding $delegation
    submit_tx "tx staking unbond $VALOPER_1 100000000$DENOM --from $happy_bonding -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --gas-prices $GAS_PRICE$DENOM" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-unbond-1 $happy_bonding $delegation

    validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    echo "Validator bond shares: ${validator_bond_shares%.*}"
    if [[ ${validator_bond_shares%.*} -ne 0  ]]; then
        echo "Unbond unsuccessful: unexpected validator bond shares amount"
        exit 1
    fi

    echo "Validator unbond from happy_liquid_1..."
    # tests/v12_upgrade/log_lsm_data.sh happy pre-unbond-2 $happy_liquid_1 $happy_liquid_1_delegation_balance
    submit_tx "tx staking unbond $VALOPER_1 $happy_liquid_1_delegation_balance$DENOM --from $happy_liquid_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --gas-prices $GAS_PRICE$DENOM" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-unbond-2 $happy_liquid_1 70000000

    echo "Validator unbond from happy_liquid_2..."
    # tests/v12_upgrade/log_lsm_data.sh happy pre-unbond-3 $happy_liquid_2 $bank_send_amount
    submit_tx "tx staking unbond $VALOPER_1 $bank_send_amount$DENOM --from $happy_liquid_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --gas-prices $GAS_PRICE$DENOM" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-unbond-3 $happy_liquid_2 $bank_send_amount

    echo "Validator unbond from happy_liquid_3..."
    # tests/v12_upgrade/log_lsm_data.sh happy pre-unbond-4 $happy_liquid_3 $ibc_transfer_amount
    submit_tx "tx staking unbond $VALOPER_1 $ibc_transfer_amount$DENOM --from $happy_liquid_3 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --gas-prices $GAS_PRICE$DENOM" $CHAIN_BINARY $HOME_1
    # tests/v12_upgrade/log_lsm_data.sh happy post-unbond-4 $happy_liquid_3 $ibc_transfer_amount

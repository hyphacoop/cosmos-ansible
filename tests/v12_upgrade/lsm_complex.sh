#!/bin/bash
# Implement complex user flows involving slashed validators
# Scenario 1: delegate - tokenize - slash - redeem
# Scenario 2: delegate - slash - tokenize - redeem

source tests/process_tx.sh

delegation=20000000
tokenize=10000000
tokenized_denom_1=$VALOPER_2/3
tokenized_denom_2=$VALOPER_2/4

# SETUP

    $CHAIN_BINARY keys add complex_bond_account --home $HOME_1
    $CHAIN_BINARY keys add complex_liquid_1 --home $HOME_1
    $CHAIN_BINARY keys add complex_liquid_2 --home $HOME_1

    complex_bond_account=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="complex_bond_account").address')
    complex_liquid_1=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="complex_liquid_1").address')
    complex_liquid_2=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="complex_liquid_2").address')

    echo "Funding bonding and tokenizing accounts..."
    submit_tx "tx bank send $WALLET_1 $complex_bond_account  100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
    submit_tx "tx bank send $WALLET_1 $complex_liquid_1 100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
    submit_tx "tx bank send $WALLET_1 $complex_liquid_2 100000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1

    echo "Delegating with complex_bond_account..."
    tests/v12_upgrade/log_lsm_data.sh complex pre-delegate-1 $complex_bond_account $delegations
    submit_tx "tx staking delegate $VALOPER_2 $delegation$DENOM --from $complex_bond_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh complex post-delegate-1 $complex_bond_account $delegations

    echo "Validator bond with complex_bond_account..."
    tests/v12_upgrade/log_lsm_data.sh complex pre-bond-1 $complex_bond_account -
    submit_tx "tx staking validator-bond $VALOPER_2 --from $complex_bond_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --gas-prices $GAS_PRICE$DENOM" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh complex post-bond-1 $complex_bond_account -

    validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    echo "Validator 2 bond shares: $validator_bond_shares"
    if [[ ${validator_bond_shares%.*} -ne $delegation  ]]; then
        echo "Validator bond unsuccessful."
        exit 1
    fi

echo "** COMPLEX CASES> 1: DELEGATE -> TOKENIZE -> SLASH -> REDEEM **"
    tests/v12_upgrade/log_lsm_data.sh complex pre-delegate-2 $complex_liquid_1 $tokenize
    submit_tx "tx staking delegate $VALOPER_2 $tokenize$DENOM --from $complex_liquid_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh complex psost-delegate-2 $complex_liquid_1 $tokenize

    delegation_balance_pre_tokenize=$($CHAIN_BINARY q staking delegations $complex_liquid_1 --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
    slash_fraction=$($CHAIN_BINARY q slashing params --home $HOME_1 -o json | jq -r '.slash_fraction_downtime')
    expected_balance=$(echo "$delegation_balance_pre_tokenize-($delegation_balance_pre_tokenize*$slash_fraction)" | bc)

    echo "Tokenizing with complex_liquid_1..."
    tests/v12_upgrade/log_lsm_data.sh complex pre-tokenize-1 $complex_liquid_1 $tokenize
    submit_tx "tx staking tokenize-share $VALOPER_2 $tokenize$DENOM $complex_liquid_1 --from $complex_liquid_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh complex post-tokenize-1 $complex_liquid_1 $tokenize

    echo "Slashing validator 2..."
    tests/v12_upgrade/log_lsm_data.sh complex pre-jail-1 $complex_liquid_1 -
    tests/major_fresh_upgrade/jail_validator.sh $PROVIDER_SERVICE_2 $VALOPER_2
    tests/v12_upgrade/log_lsm_data.sh complex post-jail-1 $complex_liquid_1 -

    echo "Redeeming with complex_liquid_1..."
    tests/v12_upgrade/log_lsm_data.sh complex pre-redeem-1 $complex_liquid_1 $tokenize
    submit_tx "tx staking redeem-tokens $tokenize$tokenized_denom_1 --from $complex_liquid_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh complex post-redeem-1 $complex_liquid_1 $tokenize

    delegation_balance_post_redeem=$($CHAIN_BINARY q staking delegations $complex_liquid_1 --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
    echo "New balance: $delegation_balance_post_redeem"
    echo "Expected new balance: ${expected_balance%.*}"

    if [[ $delegation_balance_post_redeem -ne ${expected_balance%.*} ]]; then
        echo "Complex scenario 1 failed: Unexpected post-redeem balance ($delegation_balance_post_redeem)"
        exit 1
    else
        echo "Complex scenario 1 passed".
    fi

    echo "Unjailing validator 2..."
    tests/v12_upgrade/log_lsm_data.sh complex pre-unjail-1 $WALLET_2 -
    tests/major_fresh_upgrade/unjail_validator.sh $PROVIDER_SERVICE_2 $VAL2_RPC_PORT $WALLET_2 $VALOPER_2
    tests/v12_upgrade/log_lsm_data.sh complex post-unjail-1 $WALLET_2 -

    echo "Waiting for new slash block window..."
    sleep 30

echo "** COMPLEX CASES> 2: DELEGATE -> SLASH -> TOKENIZE -> REDEEM **"
    tests/v12_upgrade/log_lsm_data.sh complex pre-delegate-3 $complex_liquid_2 $tokenize
    submit_tx "tx staking delegate $VALOPER_2 $tokenize$DENOM --from $complex_liquid_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh complex post-delegate-3 $complex_liquid_2 $tokenize

    echo "Slashing validator 2..."
    tests/v12_upgrade/log_lsm_data.sh complex pre-jail-2 $complex_liquid_2 -
    tests/major_fresh_upgrade/jail_validator.sh $PROVIDER_SERVICE_2 $VALOPER_2
    tests/v12_upgrade/log_lsm_data.sh complex post-jail-2 $complex_liquid_2 -

    downtime_period=$($CHAIN_BINARY q slashing params --home $HOME_1 -o json | jq -r '.downtime_jail_duration')
    sleep ${downtime_period%?}

    echo "Unjailing validator 2..."
    tests/v12_upgrade/log_lsm_data.sh complex pre-unjail-2 $WALLET_2 -
    tests/major_fresh_upgrade/unjail_validator.sh $PROVIDER_SERVICE_2 $VAL2_RPC_PORT $WALLET_2 $VALOPER_2
    tests/v12_upgrade/log_lsm_data.sh complex post-unjail-2 $WALLET_2 -
    delegation_balance_pre_tokenize=$($CHAIN_BINARY q staking delegations $complex_liquid_2 --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')

    echo "Tokenizing with complex_liquid_2..."
    tests/v12_upgrade/log_lsm_data.sh complex pre-tokenize-2 $complex_liquid_2 $delegation_balance_pre_tokenize
    submit_tx "tx staking tokenize-share $VALOPER_2 $delegation_balance_pre_tokenize$DENOM $complex_liquid_2 --from $complex_liquid_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh complex post-tokenize-2 $complex_liquid_2 $delegation_balance_pre_tokenize
    tokenized_balance=$($CHAIN_BINARY q bank balances $complex_liquid_2 --home $HOME_1 -o json | jq -r --arg DENOM "$tokenized_denom_2" '.balances[] | select(.denom==$DENOM).amount')

    echo "Redeeming with complex_liquid_2..."
    tests/v12_upgrade/log_lsm_data.sh complex pre-redeem-2 $complex_liquid_2 $tokenized_balance
    submit_tx "tx staking redeem-tokens $tokenized_balance$tokenized_denom_2 --from $complex_liquid_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh complex post-redeem-2 $complex_liquid_2 $tokenized_balance

    delegation_balance_post_redeem=$($CHAIN_BINARY q staking delegations $complex_liquid_2 --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')

    echo "Balance: $delegation_balance_post_redeem"
    echo "Expected balance: $delegation_balance_pre_tokenize"
    if [[ $delegation_balance_pre_tokenize -eq $delegation_balance_post_redeem ]]; then
        echo "Complex scenario 2 passed"
    elif [[ $(($delegation_balance_pre_tokenize-$delegation_balance_post_redeem)) -le 2 ]]; then
        echo "Complex scenario 2 passed: post-redeem balance is <=2$DENOM less than pre-tokenization balance ($delegation_balance_post_redeem < $delegation_balance_pre_tokenize)"
    elif [[ $(($delegation_balance_post_redeem-$delegation_balance_pre_tokenize)) -le 2 ]]; then
        echo "Complex scenario 2 passed: post-redeem balance is <=2$DENOM more than pre-tokenization balance ($delegation_balance_post_redeem > $delegation_balance_pre_tokenize)"
    else
        echo "Complex scenario 2 failed: Unexpected post-redeem balance ($delegation_balance_post_redeem)"
        exit 1
    fi

#TODO: add delegation shares check

echo "** COMPLEX CASES> CLEANUP **"

    $CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'
    echo "Unbonding from bonding account..."
    delegation_balance=$($CHAIN_BINARY q staking delegations $complex_bond_account --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
    tests/v12_upgrade/log_lsm_data.sh complex pre-unbond-1 $complex_bond_account $delegation_balance
    submit_tx "tx staking unbond $VALOPER_2 ${delegation_balance%.*}$DENOM --from complex_bond_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh complex post-unbond-1 $complex_bond_account $delegation_balance
    $CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'

    echo "Unbonding from complex_liquid_1..."
    delegation_balance=$($CHAIN_BINARY q staking delegations $complex_liquid_1 --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
    tests/v12_upgrade/log_lsm_data.sh complex pre-unbond-2 $complex_liquid_1 $delegation_balance
    submit_tx "tx staking unbond $VALOPER_2 ${delegation_balance%.*}$DENOM --from $complex_liquid_1 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh complex post-unbond-2 $complex_liquid_1 $delegation_balance
    $CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'

    echo "Unbonding from complex_liquid_1..."
    delegation_balance=$($CHAIN_BINARY q staking delegations $complex_liquid_2 --home $HOME_1 -o json | jq -r '.delegation_responses[0].balance.amount')
    tests/v12_upgrade/log_lsm_data.sh complex pre-unbond-3 $complex_liquid_2 $delegation_balance
    submit_tx "tx staking unbond $VALOPER_2 ${delegation_balance%.*}$DENOM --from $complex_liquid_2 -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh complex post-unbond-3 $complex_liquid_2 $delegation_balance
    $CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq '.'

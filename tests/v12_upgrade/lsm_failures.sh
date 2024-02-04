#!/bin/bash

source tests/process_tx.sh

bonding_delegations=20000000
liquid_delegations=150000000
liquid_tokenize=120000000
tokenized_denom="$VALOPER_1/2"

validator_cap_param=$($CHAIN_BINARY q staking params --home $HOME_1 -o json | jq -r '.validator_liquid_staking_cap')
global_cap_param=$($CHAIN_BINARY q staking params --home $HOME_1 -o json | jq -r '.global_liquid_staking_cap')

$CHAIN_BINARY keys add fail_liquid_acct1 --home $HOME_1
$CHAIN_BINARY keys add fail_liquid_acct2 --home $HOME_1
failure_bonding_account=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="fail_liquid_acct1").address')
failure_liquid_account=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="fail_liquid_acct2").address')

echo "Funding and delegating with test accounts..."
submit_tx "tx bank send $WALLET_1 $failure_bonding_account 500000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $failure_liquid_account 500000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1

tests/v12_upgrade/log_lsm_data.sh failures pre-delegate-1 $failure_bonding_account $bonding_delegations
submit_tx "tx staking delegate $VALOPER_1 $bonding_delegations$DENOM --from $failure_bonding_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-delegate-1 $failure_bonding_account $bonding_delegations
tests/v12_upgrade/log_lsm_data.sh failures pre-delegate-2 $failure_bonding_account $bonding_delegations
submit_tx "tx staking delegate $VALOPER_2 $bonding_delegations$DENOM --from $failure_bonding_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-delegate-2 $failure_bonding_account $bonding_delegations
tests/v12_upgrade/log_lsm_data.sh failures pre-delegate-3 $failure_liquid_account $liquid_delegations
submit_tx "tx staking delegate $VALOPER_1 $liquid_delegations$DENOM --from $failure_liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-delegate-3 $failure_liquid_account $liquid_delegations
tests/v12_upgrade/log_lsm_data.sh failures pre-delegate-4 $failure_liquid_account $liquid_delegations
submit_tx "tx staking delegate $VALOPER_2 $liquid_delegations$DENOM --from $failure_liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
tests/v12_upgrade/log_lsm_data.sh failures post-delegate-4 $failure_liquid_account $liquid_delegations

echo "** FAILURE CASES> 1: TOKENIZE WITH NO VALIDATOR BOND **"
    submit_bad_tx "tx staking tokenize-share $VALOPER_1 20000000$DENOM $failure_bonding_account --from $failure_bonding_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1

echo "** FAILURE CASES> 2: TOKENIZE BOND DELEGATIONS **"

    echo "Bonding to VALOPER_1 and VALOPER_2..."
    tests/v12_upgrade/log_lsm_data.sh failures pre-bond-1 $failure_bonding_account -
    submit_tx "tx staking validator-bond $VALOPER_1 --from $failure_bonding_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --gas-prices $GAS_PRICE$DENOM" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh failures post-bond-1 $failure_bonding_account -

    tests/v12_upgrade/log_lsm_data.sh failures pre-bond-2 $failure_bonding_account -
    submit_tx "tx staking validator-bond $VALOPER_2 --from $failure_bonding_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT -y --gas-prices $GAS_PRICE$DENOM" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh failures post-bond-2 $failure_bonding_account -

    validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_1 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    echo "Validator 1 bond shares: ${validator_bond_shares%.*}"
    if [[ ${validator_bond_shares%.*} -ne $bonding_delegations  ]]; then
        echo "Validator bond unsuccessful."
        exit 1
    fi
    validator_bond_shares=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.validator_bond_shares')
    echo "Validator 2 bond shares: ${validator_bond_shares%.*}"
    if [[ ${validator_bond_shares%.*} -ne $bonding_delegations  ]]; then
        echo "Validator bond unsuccessful."
        exit 1
    fi

    submit_bad_tx "tx staking tokenize-share $VALOPER_1 $bonding_delegations$DENOM $failure_bonding_account --from $failure_bonding_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1

echo "** FAILURE CASES> 3: TOKENIZE TO BREACH THE VALIDATOR LIQUID STAKING CAP **"

    validator_delegations=$($CHAIN_BINARY q staking validator $VALOPER_2 --home $HOME_1 -o json | jq -r '.delegator_shares')
    validator_cap=$(echo "$validator_delegations*$validator_cap_param" | bc)
    echo "Validator_delegations: ${validator_delegations%.*}"
    echo "Validator shares cap: ${validator_cap%.*}"

    submit_bad_tx "tx staking tokenize-share $VALOPER_2 100000000$DENOM $failure_liquid_account --from $failure_liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1

    bonded_tokens=$($CHAIN_BINARY q staking pool --home $HOME_1 -o json | jq -r '.bonded_tokens')
    global_staked=$($CHAIN_BINARY q staking total-liquid-staked --home $HOME_1 -o json | jq -r '.')
    global_cap=$(echo "$bonded_tokens*$global_cap_param" | bc)
    echo "Global shares cap: ${global_cap%.*}"
    echo "Global staked: $global_staked"

echo "** FAILURE CASES> 4: TOKENIZE TO BREACH THE GLOBAL LIQUID STAKING CAP **"

    submit_bad_tx "tx staking tokenize-share $VALOPER_1 140000000$DENOM $failure_liquid_account --from $failure_liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1

echo "** FAILURE CASES> 5: UNBOND TO BREACH THE VALIDATOR BOND FACTOR **"

    echo "Tokenizing failure_liquid_account delegations..."
    tests/v12_upgrade/log_lsm_data.sh failures pre-tokenize-1 $failure_liquid_account $liquid_tokenize
    submit_tx "tx staking tokenize-share $VALOPER_1 $liquid_tokenize$DENOM $failure_liquid_account --from $failure_liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh failures post-tokenize-1 $failure_liquid_account $liquid_tokenize

    echo "Attempting to unbond from failure_bonding_account..."
    submit_bad_tx "tx staking unbond $VALOPER_1 $bonding_delegations$DENOM --from $failure_bonding_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1

    echo "Redeeming tokens from failure_liquid_account..."
    $CHAIN_BINARY q bank balances $failure_liquid_account --home $HOME_1 -o json | jq '.balances'
    tests/v12_upgrade/log_lsm_data.sh failures pre-redeem-1 $failure_liquid_account $liquid_tokenize
    submit_tx "tx staking redeem-tokens $liquid_tokenize$tokenized_denom --from $failure_liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh failures post-redeem-1 $failure_liquid_account $liquid_tokenize

echo "** FAILURE CASES> 6: TOKENIZE AFTER DISABLING TOKENIZING **"

    submit_tx "tx staking disable-tokenize-shares --from $failure_liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    submit_bad_tx "tx staking tokenize-share $VALOPER_1 10000000$DENOM $failure_liquid_account --from $failure_liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    submit_tx "tx staking enable-tokenize-shares --from $failure_liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1

echo "** FAILURE CASES> CLEANUP **"

    echo "Unbonding delegations from failure_bonding_account and failure_liquid_account..."
    tests/v12_upgrade/log_lsm_data.sh failures pre-unbond-1 $failure_bonding_account $bonding_delegations
    submit_tx "tx staking unbond $VALOPER_1 $bonding_delegations$DENOM --from $failure_bonding_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh failures post-unbond-1 $failure_bonding_account $bonding_delegations
    tests/v12_upgrade/log_lsm_data.sh failures pre-unbond-2 $failure_bonding_account $bonding_delegations
    submit_tx "tx staking unbond $VALOPER_2 $bonding_delegations$DENOM --from $failure_bonding_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh failures post-unbond-2 $failure_bonding_account $bonding_delegations
    tests/v12_upgrade/log_lsm_data.sh failures pre-unbond-3 $failure_liquid_account $liquid_delegations
    submit_tx "tx staking unbond $VALOPER_1 $liquid_delegations$DENOM --from $failure_liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh failures post-unbond-3 $failure_liquid_account $liquid_delegations
    tests/v12_upgrade/log_lsm_data.sh failures pre-unbond-4 $failure_liquid_account $liquid_delegations
    submit_tx "tx staking unbond $VALOPER_2 $liquid_delegations$DENOM --from $failure_liquid_account -o json --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y" $CHAIN_BINARY $HOME_1
    tests/v12_upgrade/log_lsm_data.sh failures post-unbond-4 $failure_liquid_account $liquid_delegations

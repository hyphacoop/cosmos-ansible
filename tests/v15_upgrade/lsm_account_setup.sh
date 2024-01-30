#!/bin/bash
# set -x
source tests/process_tx.sh

delegation=100000000
tokenize=50000000
bank_send_amount=20000000
ibc_transfer_amount=10000000
liquid_1_redeem=20000000
tokenized_denom=$VALOPER_1/$TOKENIZATION_COUNT

$CHAIN_BINARY keys add happy_bonding --home $HOME_1
$CHAIN_BINARY keys add happy_liquid_1 --home $HOME_1
$CHAIN_BINARY keys add happy_liquid_2 --home $HOME_1
$CHAIN_BINARY keys add happy_liquid_3 --home $HOME_1
$CHAIN_BINARY keys add happy_owner --home $HOME_1

happy_bonding=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_bonding").address')
happy_liquid_1=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_liquid_1").address')
happy_liquid_2=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_liquid_2").address')
happy_liquid_3=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_liquid_3").address')
happy_owner=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_owner").address')

echo "Funding bonding and tokenizing accounts..."
submit_tx "tx bank send $WALLET_1 $happy_bonding  500000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $happy_liquid_1 500000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $happy_liquid_2 500000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $happy_liquid_3 500000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1
submit_tx "tx bank send $WALLET_1 $happy_owner 10000000uatom --from $WALLET_1 --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -o json -y" $CHAIN_BINARY $HOME_1

#!/bin/bash

# Run a tx bank send with each of the keys in the keyring

$CHAIN_BINARY tx bank send $WALLET_1 $WALLET_1 1$DENOM --home $HOME_1 --from $WALLET_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
$CHAIN_BINARY tx bank send $WALLET_2 $WALLET_2 1$DENOM --home $HOME_1 --from $WALLET_2 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
$CHAIN_BINARY tx bank send $WALLET_3 $WALLET_3 1$DENOM --home $HOME_1 --from $WALLET_3 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
$CHAIN_BINARY tx bank send $WALLET_4 $WALLET_4 1$DENOM --home $HOME_1 --from $WALLET_4 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json

happy_bonding=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_bonding").address')
happy_liquid_1=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_liquid_1").address')
happy_liquid_2=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_liquid_2").address')
happy_liquid_3=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_liquid_3").address')
happy_owner=$($CHAIN_BINARY keys list --home $HOME_1 --output json | jq -r '.[] | select(.name=="happy_owner").address')

$CHAIN_BINARY tx bank send $happy_bonding $happy_bonding 1$DENOM --home $HOME_1 --from $happy_bonding --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
$CHAIN_BINARY tx bank send $happy_liquid_1 $happy_liquid_1 1$DENOM --home $HOME_1 --from $happy_liquid_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
$CHAIN_BINARY tx bank send $happy_liquid_2 $happy_liquid_2 1$DENOM --home $HOME_1 --from $happy_liquid_2 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
$CHAIN_BINARY tx bank send $happy_liquid_3 $happy_liquid_3 1$DENOM --home $HOME_1 --from $happy_liquid_3 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
sleep $(($COMMIT_TIMEOUT+2))
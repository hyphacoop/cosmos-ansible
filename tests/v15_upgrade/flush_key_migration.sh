#!/bin/bash

# Run a tx bank send with each of the keys in the keyring

$CHAIN_BINARY tx bank send $WALLET_1 $WALLET_1 1$DENOM --home $HOME_1 --from $WALLET_1 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
$CHAIN_BINARY tx bank send $WALLET_2 $WALLET_2 1$DENOM --home $HOME_1 --from $WALLET_2 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
$CHAIN_BINARY tx bank send $WALLET_3 $WALLET_3 1$DENOM --home $HOME_1 --from $WALLET_3 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
$CHAIN_BINARY tx bank send $WALLET_4 $WALLET_4 1$DENOM --home $HOME_1 --from $WALLET_4 --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
$CHAIN_BINARY tx bank send $WALLET_RELAYER $WALLET_RELAYER 1$DENOM --home $HOME_1 --from $WALLET_RELAYER --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y -o json
#!/bin/bash
# Test IBC transfer

echo "Running with $CONSUMER_CHAIN_BINARY."

PROVIDER_CHANNEL=$1
consumer_expected_denom=ibc/$(echo -n transfer/channel-1/uatom | shasum -a 256 | cut -d ' ' -f1 | tr '[a-z]' '[A-Z]')
provider_expected_denom=ibc/$(echo -n transfer/$PROVIDER_CHANNEL/$CONSUMER_DENOM | shasum -a 256 | cut -d ' ' -f1 | tr '[a-z]' '[A-Z]')
echo "expected denom in provider: $provider_expected_denom"
echo "expected denom in consumer: $consumer_expected_denom"

$CHAIN_BINARY q ibc channel channels --home $HOME_1 -o json | jq '.'

$CONSUMER_CHAIN_BINARY --home $CONSUMER_HOME_1 q bank balances $RECIPIENT
consumer_start_balance=$($CONSUMER_CHAIN_BINARY --home $CONSUMER_HOME_1 q bank balances $RECIPIENT -o json | jq -r --arg DENOM "$consumer_expected_denom" '.balances[] | select(.denom==$DENOM).amount')
if [ -z "$consumer_start_balance" ]; then
  consumer_start_balance=0
fi
echo "Consumer starting balance in expected denom: $consumer_start_balance"

# Transfer provider token to consumer chain
echo "Sending $DENOM to $CONSUMER_CHAIN_ID..."
$CHAIN_BINARY --home $HOME_1 tx ibc-transfer transfer transfer $PROVIDER_CHANNEL $RECIPIENT 1000$DENOM --from $WALLET_1 --keyring-backend test --gas $GAS --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$DENOM -y
echo "Waiting for the transfer to reach the consumer chain..."
sleep $(($COMMIT_TIMEOUT*15))
$CONSUMER_CHAIN_BINARY --home $CONSUMER_HOME_1 q bank balances $RECIPIENT

consumer_end_balance=$($CONSUMER_CHAIN_BINARY --home $CONSUMER_HOME_1 q bank balances $RECIPIENT -o json | jq -r --arg DENOM "$consumer_expected_denom" '.balances[] | select(.denom==$DENOM).amount')
if [ -z "$consumer_end_balance" ]; then
  consumer_end_balance=0
fi
echo "Consumer ending balance in expected denom: $consumer_end_balance"

if [ $consumer_end_balance -gt $consumer_start_balance ]; then
  echo "Consumer balance has increased!"
else
  echo "Consumer balance has not increased!"
  exit 1
fi

$CHAIN_BINARY --home $HOME_1 q bank balances $WALLET_1
provider_start_balance=$($CHAIN_BINARY --home $HOME_1 q bank balances $WALLET_1 -o json | jq -r --arg DENOM "$provider_expected_denom" '.balances[] | select(.denom==$DENOM).amount')
if [ -z "$provider_start_balance" ]; then
  provider_start_balance=0
fi
echo "Provider starting balance in expected denom: $provider_start_balance"

# Transfer consumer token to provider chain
$CHAIN_BINARY q ibc channel channels --home $CONSUMER_HOME_1 -o json | jq '.'
$CHAIN_BINARY q tendermint-validator-set --home $HOME_1
$CHAIN_BINARY q tendermint-validator-set --home $CONSUMER_HOME_1
DENOM_BEFORE=$($CHAIN_BINARY --home $HOME_1 q bank balances $WALLET_1 -o json | jq -r '.balances | length')
echo "Sending $CONSUMER_DENOM to $CHAIN_ID..."
command="$CONSUMER_CHAIN_BINARY --home $CONSUMER_HOME_1 tx ibc-transfer transfer transfer channel-1 $WALLET_1 1000$CONSUMER_DENOM --from $RECIPIENT --keyring-backend test --gas auto --gas-adjustment $GAS_ADJUSTMENT --gas-prices $GAS_PRICE$CONSUMER_DENOM -y -o json"
txhash=$($command | jq -r .txhash)
echo "Waiting for the transfer to reach the provider chain..."
sleep $(($COMMIT_TIMEOUT*20))
echo "tx hash: $txhash"
$CONSUMER_CHAIN_BINARY q tx $txhash --home $CONSUMER_HOME_1

$CHAIN_BINARY --home $HOME_1 q bank balances $WALLET_1
provider_end_balance=$($CHAIN_BINARY --home $HOME_1 q bank balances $WALLET_1 -o json | jq -r --arg DENOM "$provider_expected_denom" '.balances[] | select(.denom==$DENOM).amount')
if [ -z "$provider_end_balance" ]; then
  provider_end_balance=0
fi
echo "Provider ending balance in expected denom: $provider_end_balance"

if [ $provider_end_balance -gt $provider_start_balance ]; then
  echo "Provider balance has increased!"
else
  echo "Provider balance has not increased!"
  exit 1
fi

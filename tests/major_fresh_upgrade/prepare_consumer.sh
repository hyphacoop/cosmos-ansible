#!/bin/bash
# Prepare a consumer chain to be started

# echo "Patching add template with spawn time..."
# spawn_time=$(date -u --iso-8601=ns | sed s/+00:00/Z/ | sed s/,/./)
# jq -r --arg SPAWNTIME "$spawn_time" '.spawn_time |= $SPAWNTIME' tests/patch_upgrade/proposal-add-template.json > proposal-add-spawn.json
# sed "s%\"chain_id\": \"\"%\"chain_id\": \"$CONSUMER_CHAIN_ID\"%g" proposal-add-spawn.json > proposal-add-$CONSUMER_CHAIN_ID.json
# rm proposal-add-spawn.json

# echo "Submitting proposal..."

$CHAIN_BINARY q provider list-consumer-chains --home $HOME_1

echo "Collecting the CCV state..."
$CHAIN_BINARY q provider consumer-genesis $CONSUMER_CHAIN_ID -o json --home $HOME_1 > ccv-pre.json
jq '.params |= . + {"soft_opt_out_threshold": "0.10"}' ccv-pre.json > ccv-optout.json


echo "Patching the CCV state with the provider reward denom"
jq --arg DENOM "$CONSUMER_DENOM" '.params.reward_denoms = [$DENOM]' ccv-optout.json > ccv-reward.json
cp ccv-reward.json ccv.json

if $ICS_120 ; then
    echo "Patching for ICS v1.2.0"
    jq 'del(.preCCV)' ccv.json > ccv-120.json
    cp ccv-120.json ccv.json
fi

if $ICS_200 ; then
    if [ $COSMOS_SDK == "v47" ]; then
        $ICS_TRANSFORM_BINARY genesis transform --to v2.x ccv.json > ccv-transform.json
        cp ccv-transform.json ccv.json
    fi
fi

if $ICS_310 ; then
    if [ $COSMOS_SDK == "v47" ]; then
        $ICS_TRANSFORM_BINARY genesis transform --to v3.1.x ccv.json > ccv-transform.json
        cp ccv-transform.json ccv.json
    fi
fi

if [ "$CONSUMER_ICS" == "v3.3.0" ]; then
    if [ "$PROVIDER_ICS" != "v3.3.0" ]; then
        echo "Patching for ICS v3.3.0"
        $CONSUMER_CHAIN_BINARY genesis transform ccv.json > ccv-330-1.json
        cp ccv-330-1.json ccv.json
    fi
fi

if [ "$CONSUMER_ICS" == "v4.0.0" ]; then
    if [ "$PROVIDER_ICS" != "v4.0.0" ]; then
        echo "Patching for ICS v4.0.0 consumer"
        $CONSUMER_CHAIN_BINARY genesis transform ccv.json > ccv-400-1.json
        cp ccv-400-1.json ccv.json
    fi
fi

echo "Patching the consumer genesis file..."
jq -s '.[0].app_state.ccvconsumer = .[1] | .[0]' $CONSUMER_HOME_1/config/genesis.json ccv.json > consumer-genesis.json
cp consumer-genesis.json $CONSUMER_HOME_1/config/genesis.json
cp consumer-genesis.json $CONSUMER_HOME_2/config/genesis.json
cp consumer-genesis.json $CONSUMER_HOME_3/config/genesis.json

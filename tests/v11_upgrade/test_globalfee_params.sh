#!/bin/bash 
# Verify globalfee params are set properly

# Collect globalfee params post-upgrade
$CHAIN_BINARY q globalfee params -o json --home $HOME_1 > globalfee-post-upgrade.json

# 1. Min gas prices are the same
min_gas_prices_pre=$(jq '.minimum_gas_prices' globalfee-pre-upgrade.json)
min_gas_prices_post=$(jq '.minimum_gas_prices' globalfee-post-upgrade.json)

if [ "$min_gas_prices_pre" != "$min_gas_prices_post" ]; then
    echo "Min gas prices do not match before and after the upgrade."
    exit 1
else
    echo "Min gas prices match before and after the upgrade."
fi

# 2. Bypass msg types are added

MSG_RECV_PACKET=$(jq '.bypass_min_fee_msg_types | index("/ibc.core.channel.v1.MsgRecvPacket")' globalfee-post-upgrade.json)
MSG_ACK=$(jq '.bypass_min_fee_msg_types | index("/ibc.core.channel.v1.MsgAcknowledgement")' globalfee-post-upgrade.json)
MSG_UPDATE_CLIENT=$(jq '.bypass_min_fee_msg_types | index("/ibc.core.client.v1.MsgUpdateClient")' globalfee-post-upgrade.json)
MSG_TIMEOUT=$(jq '.bypass_min_fee_msg_types | index("/ibc.core.channel.v1.MsgTimeout")' globalfee-post-upgrade.json)
MSG_TIMEOUT_ON_CLOSE=$(jq '.bypass_min_fee_msg_types | index("/ibc.core.channel.v1.MsgTimeoutOnClose")' globalfee-post-upgrade.json)

if [ -z $MSG_RECV_PACKET ]; then
    echo "/ibc.core.channel.v1.MsgRecvPacket is not listed in the bypass message types."
    exit 1
else
    echo "/ibc.core.channel.v1.MsgRecvPacket is listed in the bypass message types."
fi

if [ -z $MSG_ACK ]; then
    echo "/ibc.core.channel.v1.MsgAcknowledgement is not listed in the bypass message types."
    exit 1
else
    echo "/ibc.core.channel.v1.MsgAcknowledgement is listed in the bypass message types."
fi

if [ -z $MSG_UPDATE_CLIENT ]; then
    echo "/ibc.core.client.v1.MsgUpdateClient is not listed in the bypass message types."
    exit 1
else
    echo "/ibc.core.client.v1.MsgUpdateClient is listed in the bypass message types."
fi

if [ -z $MSG_TIMEOUT ]; then
    echo "/ibc.core.channel.v1.MsgTimeout is not listed in the bypass message types."
    exit 1
else
    echo "/ibc.core.channel.v1.MsgTimeout is listed in the bypass message types."
fi

if [ -z $MSG_TIMEOUT_ON_CLOSE ]; then
    echo "/ibc.core.channel.v1.MsgTimeoutOnClose is not listed in the bypass message types."
    exit 1
else
    echo "/ibc.core.channel.v1.MsgTimeoutOnClose is listed in the bypass message types."
fi

# 3. Max total bypass gas usage

MAX_USAGE=$(jq -r '.max_total_bypass_min_fee_msg_gas_usage' globalfee-post-upgrade.json)
if [ -z $MSG_TIMEOUT_ON_CLOSE ]; then
    echo "max_total_bypass_min_fee_msg_gas_usage is not set."
    exit 1
else
    echo "max_total_bypass_min_fee_msg_gas_usage is set."
fi
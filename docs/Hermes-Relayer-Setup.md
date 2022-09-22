# Hermes IBC Relayer Setup Guide

This guide will assist you in setting up two chains connected through an IBC relayer.

- It is recommended Debian 11 is used for all host machines.

## Overview

We will use a scenario in which the hosts are set up in the `dev.testnet.com` domain. This is an example domain, you should replace it with your own.

The hosts listed in the example [inventory file](/examples/inventory-hermes.yml) are:
* Chain 1 host: `my-chain-1.dev.testnet.com`
* Chain 2 host: `my-chain-2.dev.testnet.com`
* Hermes relayer: `hermes.dev.testnet.com`

Once the relayer is operational, you will be able to send messages between both chains using the `ibc transfer` command.

See the [Hermes Guide](https://hermes.informal.systems/index.html) for additional information.

## Chains Settings

* **Gaia version:** `v7.0.0`
* **Chain IDs:** `my-chain-1` and `my-chain-2`
* **Hermes version:** `v1.0.0`

## Workflow

1. Configure the inventory file.
2. Run the `hermes.yml` playbook.
3. Test the relayer.

## Prerequisites

### DNS

- A/AAAA records must be set up for both chains and the relayer prior to running the playbook.

## Deployment

### Configure the Inventory File

Make the following modifications to [inventory-hermes.yml](/examples/inventory-hermes.yml):
  - Replace the `dev.testnet.com` address with your own in the `hosts` variable.
  - Replace the chain IDs in the `hermes_chains` variable with the IDs of the chains being relayed to.
  - Replace the default mnemonic file paths in `hermes_relayer_mnemonic` for both chains. You can replace those with `hermes_relayer_key` and `hermes_relayer_mnemonics` with `hermes_relayer_keys` if you want to use key files instead.
  - Replace the hosts in the `hermes_chain_rpc_*` and `hermes_chain_grpc_*` variables with the endpoints that Hermes will connect to.
  - A key file in this case is the output from `gaiad keys add <wallet_name> --output json`.

### Run the Playbook 

If the chains are already set up and you only want to install the relayer, you can comment or delete the `Set up chains` task in the `hermes.yml` play:
```
ansible-galaxy install -r requirements.yml
ansible-playbook hermes.yml -i examples/inventory-hermes.yml
```

The channels that are created as part of the play will be saved under `/home/hermes/<chain_id>-<connection_id>.txt` for each chain in the `hermes` machine.

### Test the Relayer

You can now send messages between `my-chain-1` and `my-chain-2` using the `gaiad tx ibc-transfer` command. In the example below, `hermes` created `channel-0`.
```
gaiad tx ibc-transfer transfer transfer channel-0 [cosmos address of receiver] 1000uatom --chain-id [chain we are sending from] --from [cosmos address of sender] --fees 500uatom --gas auto -y
```

# Hermes IBC Relayer Setup Guide

This guide will assist you in setting up a relayer host between two chains.

- It is recommended Debian 11 is used for all host machines.

## Overview

We will use a scenario in which one host is set up in the `dev.testnet.com` domain. This is an example domain, you should replace it with your own.

The hosts listed in the example [inventory file](/examples/inventory-hermes.yml) are:
* Chain 1 host: `chain-1.dev.testnet.com`
* Chain 2 host: `chain-2.dev.testnet.com`
* Hermes relayer: `hermes.dev.testnet.com`

Once the relayer is operational, you will be able to send messages between both chains using the `ibc transfer` command.


## Chains Settings

* **Gaia version:** `v7.0.0`
* **Chain IDs:** `chain-1` and `chain-2`

## Workflow

1. Configure the inventory file.
2. Run the `hermes.yml` playbook.
3. Connect the chains.


## Prerequisites

### DNS

- Set up an appropriate `A` record for Let's Encrypt.

### Chains

- Both chains being connected must be online.
- The mnemonic for an account with tokens in it must be available for both chains.

## Deployment

### Configure the Inventory File

Make the following modifications to [inventory-hermes.yml](/examples/inventory-hermes.yml):
  - Replace the `dev.testnet.com` address with your own in the `hosts` variable.
  - Replace the chain IDs in the `hermes_chains` variable with the IDs of the chains being relayed to.
  - Replace the hosts in the `hermes_chain_hostname` variables with the endpoints that Hermes will connect to.
  - Replace the `validator@devnet.com` address with your own in the `letsencrypt_email` variable.
  - Add the addresses of the accounts you want to airdrop tokens to in the `gaiad_airdrop_accounts` variable.


### Run the playbook 

```
ansible-playbook hermes.yml -i examples/inventory-hermes.yml
```

### Connect the chains

Run the following commands in the Hermes host after running the playbook.

Switch to the `hermes` user.
```
su hermes
```

Restore the account key for the chains you want to relay to. Each key name must match the chain ID, in this example they are `chain-1` and `chain-2`.
```
~/bin/hermes -c ~/.hermes/config.toml keys restore chain-1 -m "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"

~/bin/hermes -c ~/.hermes/config.toml keys restore chain-2 -m "abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon garage"
```

Create a client between the chains.
```
~/bin/hermes -c ~/.hermes/config.toml create client chain-1 chain-2
```

Create a channel between the chains.
```
~/bin/hermes -c ~/.hermes/config.toml create channel --port-a transfer --port-b transfer chain-1 chain-2
```

Log out as the `hermes` user.
```
exit
```

Restart the hermes service.
```
systemctl restart hermes
```

You can now send messages between `chain-1` and `chain-2` using the `gaiad tx ibc-transfer` command. In the example below, `hermes` created `channel-329`.
```
gaiad tx ibc-transfer transfer transfer channel-329 [cosmos address of receiver] 1000uatom --chain-id [chain we are sending from] --from [cosmos address of sender] --fees 500uatom --gas auto -y
```
# Hermes IBC Relayer Setup Guide

This guide will assist you in setting up a relayer host between two chains.

- It is recommended Debian 11 is used for all host machines.

## Overview

We will use a scenario in which the hosts are set up in the `dev.testnet.com` domain. This is an example domain, you should replace it with your own.

The hosts listed in the example [inventory file](/examples/inventory-hermes.yml) are:
* Chain 1 host: `my-chain-1.dev.testnet.com`
* Chain 2 host: `my-chain-2.dev.testnet.com`
* Hermes relayer: `hermes.dev.testnet.com`

Once the relayer is operational, you will be able to send messages between both chains using the `ibc transfer` command.


## Chains Settings

* **Gaia version:** `v7.0.0`
* **Chain IDs:** `my-chain-1` and `my-chain-2`
* **Hermes version:** `v1.0.0`

## Workflow

1. Configure the inventory file.
2. Run the `hermes.yml` playbook.
3. Connect the chains.


## Prerequisites

### DNS

- Set up appropriate `A` and `AAAA` records for Let's Encrypt.

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
  - Add the addresses of the accounts you want to airdrop tokens to in the `chain_airdrop_accounts` variable.


### Run the playbook 

```
ansible-galaxy install -r requirements.yml
ansible-playbook hermes.yml -i examples/inventory-hermes.yml
```

### Connect the chains

Run the following commands in the Hermes host after running the playbook.

Switch to the `hermes` user.
```
su hermes
cd ~
```

For each chain, copy the mnemonic of the relayer account to a text file:
- `my-chain-1-relayer-mnemonic.txt`
- `my-chain-2-relayer-mnemonic.txt`

Restore the relayer account key for both chains.
```
~/bin/hermes keys add --chain my-chain-1 --mnemonic-file my-chain-1-relayer-mnemonic.txt
~/bin/hermes keys add --chain my-chain-2 --mnemonic-file my-chain-2-relayer-mnemonic.txt
```

Create a connection between the chains.
```
~/bin/hermes create connection --a-chain my-chain-1 --b-chain my-chain-2
```

Note down the `ConnectionId` returned.

Create a channel between the chains using the chain name and `ConnectionID` above for this example we use `connection-0`
```
~/bin/hermes create channel --a-chain my-chain-1 --a-port transfer --b-port transfer --order unordered --a-connection connection-0
```

Note down and save the `ChannelId` for both chains. You will need it whenever you want to make IBC transfers, as shown below.

Log out as the `hermes` user.
```
exit
```

Restart the hermes service.
```
systemctl restart hermes
```

You can now send messages between `my-chain-1` and `my-chain-2` using the `gaiad tx ibc-transfer` command. In the example below, `hermes` created `channel-0`.
```
gaiad tx ibc-transfer transfer transfer channel-0 [cosmos address of receiver] 1000uatom --chain-id [chain we are sending from] --from [cosmos address of sender] --fees 500uatom --gas auto -y
```

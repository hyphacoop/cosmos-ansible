# Multi-Node Testnet Setup Guide

This guide will assist you in setting up all the infrastructure you may need to run a multi-node testnet.

- It is recommended Debian 11 is used for all host machines.

## Overview

We will use a scenario in which several hosts need to be set up on the `cosmostest.network` domain. This is an example domain, you should replace it with your own.

The set of hosts includes several chain nodes and a monitoring host. Once these hosts are operational and the chain is live, any new node will be able to connect to the network and sync to the current block height.

### Chain settings

* **Gaia version**: `v7.0.3`
* **Chain ID**: `cosmos-testnet`
* **Stake denom**: `uatom`

### Validators

The chain will start with three validators that together make up 100% of the voting power.
* `val1.cosmostest.network`: 40%
* `val2.cosmostest.network`: 30%
* `val3.cosmostest.network`: 30%

### Sentry nodes

Two sentry nodes are responsible for protecting the validators from DDoS attacks.
* `sen1.cosmostest.network`
* `sen2.cosmostest.network`

### State sync node

State sync nodes will serve chain snapshots every 1000 blocks.

* `sync1.cosmostest.network`
* `sync2.cosmostest.network`

### Monitoring

A monitor host will provide a dashboard for checking the health of the testnet, including the current block height, transaction stats, peers, etc.

* `monitor.cosmostest.network`

## Workflow

We can divide the deployment into the following stages: 

1. Set up the monitor host.
2. (Optional) Prepare the genesis file and validator keys.
3. Configure the inventory file.
4. Run the `node.yml` playbook from the [cosmos-ansible](https://github.com/hyphacoop/cosmos-ansible/) repo.

## Prerequisites

### DNS

Each host must have an `A` and `AAAA` record.
All hosts except for the monitor must have a set of CNAMEs to the host to provide the relevant interface.

In the table below, `<host>` acts as a placeholder for `val1`, `val2`, `val3`, `sen1`, `sen2`, `sync1` and `sync2`.
  

|  Host  | Subdomain  |  DNS records |
|------|-|-|
| `<host>.cosmostest.network`| - | `A` to IPv4 address <br> `AAAA` to IPv6 address
| | `rest.<host>.cosmostest.network` | `CNAME` to `<host>.cosmostest.network` |
| | `grpc.<host>.cosmostest.network` | `CNAME` to `<host>.cosmostest.network` |
| | `rpc.<host>.cosmostest.network` | `CNAME` to `<host>.cosmostest.network` |
| | `p2p.<host>.cosmostest.network` | `CNAME` to `<host>.cosmostest.network` |
| `monitor.cosmostest.network` | -  |  `A` to IPv4 address <br> `AAAA` to IPv6 address |


### SSL

We must provide an email for the Let's Encrypt certificate. For this example we will use `validator@cosmostest.network`.

### Grafana

We must provide the SSH address for the Grafana monitor host. For this example we will use `root@monitor.cosmostest.network`.

### PANIC

We must provide the SSH address for the PANIC monitor host. For this example we will use `root@monitor.cosmostest.network`.

## Deployment

### Set up the Monitor Host

Follow the instructions in the [Testnet Monitoring Setup Guide](/docs/Testnet-Monitoring-Setup.md) page to set up the monitor host.

### (Optional) Prepare the genesis file and validator keys

*These steps can now be done automatically with our ansible playbook, please refer to [/examples/README.md](/examples/README.md#start-a-three-node-testnet-from-scratch)*

We will use a stand-alone install of gaia to generate a genesis file and keys for the three validator nodes. You can do this on a development machine.

Set up the environment and install Go 1.18
```
apt update
apt dist-upgrade
apt install git make build-essential
wget -q -O - https://git.io/vQhTU | bash -s -- --version 1.18
```

Install Gaia v7.0.0
```
cd ~
git clone https://github.com/cosmos/gaia.git
cd gaia
git checkout v7.0.0
make install
```

Create a home folder for each validator
```
gaiad init val1 --chain-id cosmos-testnet --home ~/gaia-val1
gaiad init val2 --chain-id cosmos-testnet --home ~/gaia-val2
gaiad init val3 --chain-id cosmos-testnet --home ~/gaia-val3
```

Obtain node IDs and public keys
```
gaiad tendermint show-node-id --home ~/gaia-val1
gaiad tendermint show-node-id --home ~/gaia-val2
gaiad tendermint show-node-id --home ~/gaia-val3
gaiad tendermint show-validator --home ~/gaia-val1
gaiad tendermint show-validator --home ~/gaia-val2
gaiad tendermint show-validator --home ~/gaia-val3
```

We will work off the `gaia-val1` home folder from now on.
```
cd ~/gaia-val1/config
```

Modify the genesis file to replace all instances of `stake` with `uatom`
```
sed -i s%stake%uatom%g genesis.json
```

Create self-delegation accounts: save the mnemonics shown in the output.
```
gaiad keys add val1 --keyring-backend test --home ~/gaia-val1
gaiad keys add val2 --keyring-backend test --home ~/gaia-val1
gaiad keys add val3 --keyring-backend test --home ~/gaia-val1
```

Add funds to accounts
```
gaiad add-genesis-account val1 140000000uatom --keyring-backend test --home ~/gaia-val1
gaiad add-genesis-account val2 130000000uatom --keyring-backend test --home ~/gaia-val1
gaiad add-genesis-account val3 130000000uatom --keyring-backend test --home ~/gaia-val1
```

Create gentx transactions to create validators
```
cd ~/gaia-val1/config
mkdir gentx
cd gentx
gaiad gentx val1 40000000uatom --pubkey '<val1 pubkey>' --node-id <val1 node-id> --moniker val1 --chain-id cosmos-testnet --keyring-backend test --home ~/gaia-val1 --output-document val1-gentx.json
gaiad gentx val2 30000000uatom --pubkey '<val2 pubkey>' --node-id <val2 node-id> --moniker val2 --chain-id cosmos-testnet --keyring-backend test --home ~/gaia-val1 --output-document val2-gentx.json
gaiad gentx val3 30000000uatom --pubkey '<val3 pubkey>' --node-id <val3 node-id> --moniker val3 --chain-id cosmos-testnet --keyring-backend test --home ~/gaia-val1 --output-document val3-gentx.json

```

Collect gentx messages
``` 
gaiad collect-gentxs --home ~/gaia-val1
```

Collect the following files:
- `~/gaia-val1/config/genesis.json`
- `~/gaia-val1/config/node_key.json`
- `~/gaia-val1/config/priv_validator_key.json`
- `~/gaia-val2/config/node_key.json`
- `~/gaia-val2/config/priv_validator_key.json`
- `~/gaia-val3/config/node_key.json`
- `~/gaia-val3/config/priv_validator_key.json`


### Configure the Inventory

Make the following modifications to [inventory-multi-node.yml](/examples/inventory-multi-node.yml):
- Addresses for the validator, sentry, sync, and monitor hosts.
- `genesis_node` defines the node where the secondary validators are initialized before being transferred to the validators nodes.
- `bonded_tokens_pool` for the chain.
- `voting_power` for each validator.
- `validator_moniker` defines the moniker for the validator.

### Run the playbook 

```
ansible-galaxy install -r requirements.yml
ansible-playbook node.yml -i inventory-multi-node.yml
```

We can verify the chain is live by logging into any node machine and running `journalctl -fu cosmovisor`.

The monitor host will start getting data at this point.

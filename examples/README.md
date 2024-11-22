# Examples

Sample inventory files are provided here as reference.

After a playbook is run, you can log into a node and see if the chain is running with one of these commands:

|          Inventory file          | `journalctl` command                |
| :------------------------------: | ----------------------------------- |
| `use_cosmovisor: true` (default) | `journalctl -fu cosmovisor.service` |
|     `use_cosmovisor: false`      | `journalctl -fu gaiad.service`      |

Gaia is set up for the `gaia` user by default. Log into the node and switch to the `gaia` user to run `gaiad` commands.

## Install dependencies

Before running any playbooks, first install the Ansible dependencies:

```
ansible-galaxy install -r requirements.yml
```

## Join the Cosmos Hub Release Testnet

Set up a node to join the Cosmos Hub [release testnet](https://github.com/cosmos/testnets/tree/master/release) using state sync.

* **Inventory file:** [`inventory-release-testnet.yml`](inventory-release-testnet.yml)
* **Chain ID:** `theta-testnet-001`
* **Gaia version:** `v21.0.1`

### Run the playbook 

```
ansible-playbook node.yml -i examples/inventory-release-testnet.yml -e 'target=SERVER_IP_OR_DOMAIN'
```

This playbook obtains a trust block height and the corresponding hash ID from the first RPC server listed in the inventory file in order to use the state sync feature. 

## Join the Interchain Security Testnet

Set up nodes to join the [Interchain Security Testnet](https://github.com/cosmos/testnets/tree/master/interchain-security).

### Provider Chain

* **Inventory file:** [`inventory-ics-testnet-provider.yml`](inventory-ics-testnet-provider.yml)
* **Chain ID:** `provider`
* **Gaia version:** `v21.0.1`

Run the playbook:
```
ansible-playbook node.yml -i examples/inventory-ics-testnet-provider.yml -e 'target=SERVER_IP_OR_DOMAIN'
```

If you want to run a validator, do the following after this play has finished running and continue to join the consumer chains:

1. Make a copy of the keys in the `/home/provider/.gaia/config` folder in the target machine. You will need them to set up the consumer chain validators:
- `priv_validator_key.json`
- `node_key.json`

2. If you have not set up a validator, generate a keypair for it:
```
gaiad keys add <validator_keypair_name> --home ~/.gaia --keyring-backend test --output json > ~/validator-keypair.json 2>&1
```

---

### `pion-1` Consumer Chain

* **Inventory file:** [`inventory-ics-testnet-pion-1.yml`](inventory-ics-testnet-pion-1.yml)
* **Chain ID:** `pion-1`

Run the playbook using the keys collected from the provider chain node:
```
ansible-playbook node.yml -i examples/inventory-ics-testnet-pion-1.yml -e 'target=SERVER_IP_OR_DOMAIN node_key_file=node_key.json priv_validator_key_file=priv_validator_key.json"
```

---

To set up a validator, do the following after the consumer chain plays have finished running and all nodes are synced:

3. Get tokens for your validator address.
4. Bond the validator on the provider chain:
```
gaiad tx staking create-validator --amount 2000000uatom --pubkey <validator_public_key> --from <validator_keypair_name> --keyring-backend test --home ~/.gaia --chain-id provider --commission-max-change-rate 0.01 --commission-max-rate 0.2 --commission-rate 0.1 --moniker <validator_moniker> --min-self-delegation 1 -y
```

For more information, see the [validator joining guide](https://github.com/cosmos/testnets/blob/master/interchain-security/VALIDATOR_JOINING_GUIDE.md).

## Start a Local Testnet

Set up a node with a single validator account.

* **Inventory file:** [`inventory-local.yml`](inventory-local.yml)
* **Chain ID:** `my-testnet`
* **Moniker:** `cosmos-node`
* **Gaia version:** `v21.0.1`
* **Faucet REST server**

### Run the Playbook

```
ansible-playbook node.yml -i examples/inventory-local.yml -e 'target=SERVER_IP_OR_DOMAIN'
```

- The validator address and mnemonic will be saved to `/home/gaia/.gaia/validator.json` in the host.
- The faucet address and mnemonic will be saved to `/home/gaia/.gaia/faucet.json` in the host.
- The faucet REST server will listen on port `8000` by default, this can be changed with the `faucet_port` variable.

## Start a Local Testnet Using a Modified Genesis File

Set up a node with a single validator account and a modified genesis file that makes the chain start at a non-zero block height. The resulting node will be similar to [this configuration](https://github.com/cosmos/testnets/tree/master/local).

The playbook will download the genesis file, and the validator keys are listed below.

* **Inventory file:** [`inventory-local-genesis.yml`](inventory-local-genesis.yml)
* **Chain ID:** `local-testnet`
* **Gaia version:** `14.1.0`
* **Validator mnemonic:** [self-delegation-wallet-mnemonic.txt](validator-keys/validator-40/self-delegation-wallet-mnemonic.txt)
* **Validator key:** [priv_validator_key.json](validator-keys/validator-40/priv_validator_key.json)
* **Node key:** [node_key.json](validator-keys/validator-40/node_key.json)

### Run the playbook

```
ansible-playbook node.yml -i examples/inventory-local-genesis.yml -e 'target=SERVER_IP_OR_DOMAIN'
```

## Start a three-node testnet from existing keys and genesis file

Set up a chain with three validator nodes that have the following voting power:

| Validator moniker | Voting power | Self-delegating address                         |
| :---------------: | :----------: | ----------------------------------------------- |
|  `validator-40`   |     40%      | `cosmos1r5v5srda7xfth3hn2s26txvrcrntldjumt8mhl` |
|  `validator-32`   |     32%      | `cosmos1ay4dpm0kjmvtpug28vgw5w32yyjxa5sp97pjqq` |
|  `validator-28`   |     28%      | `cosmos1v8zgdpzqfazvk6fgwhqqhzx0hfannrajezuc6t` |

Each of the validators has a balance of 100 000 000 uatom.

- **Inventory file:** [`inventory-three-node.yml`](inventory-three-node.yml)
- **Chain ID:** `cosmos-testnet`
- **Gaia version:** `v17.2.0`

Refer to the [Multi-Node Testnet Setup](/docs/Multi-Node-Testnet-Setup.md) guide in the `docs` folder to learn how these accounts were created and how you can set up a genesis file and private keys if you want to further customize your testnet.

### Requirements

- Inventory file
  - Replace the addresses below with your own in the `p2p_persistent_peers` and `hosts` variables.
    - `validator-40.testnet.com`
    - `validator-32.testnet.com`
    - `validator-28.testnet.com`

### Run the Playbook

```
ansible-playbook node.yml -i examples/inventory-three-node.yml
```

## Start a three-node testnet from scratch
Set up a chain with three validator nodes that have the following voting power:

| Validator moniker | Voting power |
|:-----------------:|:------------:|
|  `validator-40`   |     40%      |
|  `validator-32`   |     32%      |
|  `validator-28`   |     28%      |

- **Inventory file:** [`inventory-three-node-scratch.yml`](inventory-three-node-scratch.yml)
- **Chain ID:** `cosmos-testnet`
- **Gaia version:** `v17.2.0`

Refer to the [Multi-Node Testnet Setup](/docs/Multi-Node-Testnet-Setup.md) guide in the `docs` folder if you want to further customize your testnet.

### Requirements

- Inventory file
  - Replace the addresses below with your own in the genesis_node and hosts variables.
    - `validator-40.testnet.com`
    - `validator-32.testnet.com`
    - `validator-28.testnet.com`

### Run the Playbook

```
ansible-playbook node.yml -i examples/inventory-three-node-scratch.yml
```

## Start a Single-Node Developer Testnet

Set up a host as a single-node developer testnet.

- This network is meant to be exposed to the public.
- The playbook obtains a certificate from Let's Encrypt and sets up an SSL proxy.
- Airdrop addresses can be entered in the inventory file.

* **Inventory file:** [`inventory-dev.yml`](inventory-dev.yml)
* **Chain ID:** `my-devnet`
* **Gaia version:** `v21.0.1`

### Requirements

- DNS
  - Set up an appropriate A record for Let's Encrypt.
- Inventory file
  - Replace the `validator@devnet.com` address with your own in the `letsencrypt_email` variable.
  - Add the addresses of the accounts you want to airdrop tokens to in the `chain_airdrop_accounts` variable.
 
  
### Run the playbook 

```
ansible-playbook node.yml -i examples/inventory-dev.yml -e 'target=SERVER_IP_OR_DOMAIN'
```

## Start a Multi-Node Testnet

Set up multiple hosts to run a testnet with validator, sentry, and sync nodes.

* **Inventory file:** [`inventory-multi-node.yml`](inventory-multi-node.yml)

Follow the [Multi-Node Testnet Setup](/docs/Multi-Node-Testnet-Setup.md) guide in the `docs` folder for all the requirements and steps needed to deploy this network. 

If you want to set up a monitoring host, the [Testnet Monitoring Setup](/docs/Testnet-Monitoring-Setup.md) guide includes instructions for setting up dashboards and alert services using the multi-node testnet as an example.

## Set up an IBC Testnet

Deploy two single-validator chains connected through a Hermes relayer.

* **Inventory file:** [`inventory-hermes.yml`](inventory-hermes.yml)

### Requirements

- Inventory file
  - Replace the `hermes.dev.testnet.com` address with your own in the `hosts` section.
  - Chains
    - Replace `my-chain-1` and `my-chain-2` in the `hermes_chains` key with the chain IDs that the relayer will connect.
    - Enter the address for each node in the `hermes_chain_rpc_hostname` and `hermes_chain_grpc_hostname` variables, as well as the relevant ports in the `_port` variables.
  - (Optional) Key files for relayer accounts
    - If you want to use key files instead of mnemonic ones, replace `hermes_relayer_mnemonics: true` with `hermes_relayer_keys: true`.
    - Replace `hermes_relayer_mnemonic` with `hermes_relayer_key` for both chains and add the paths to the key files.
    - The key file is the output from `gaiad keys add <wallet_name> --output json`.

### Run the playbook 

```
ansible-playbook hermes.yml -i examples/inventory-hermes.yml
```

- The channels that are created as part of the play will be saved under `/home/hermes/<chain_id>-<connection_id>.txt` for each chain.
- See the [Hermes Guide](https://hermes.informal.systems/index.html) for additional information.

## Set up a Big Dipper 2.0 Block Explorer

Run a block explorer for the Theta testnet using [Big Dipper](https://bigdipper.live/).

* **Inventory file:** [`inventory-bigdipper.yml`](inventory-bigdipper.yml)

### Requirements

* A full node must be running for Big Dipper to collect data from. You can set up an archive node for the Theta testnet as follows:
    ```
    ansible-playbook node.yml -i examples/inventory-theta.yml -e 'target=ARCHIVE_NODE_ADDRESS chain_version=v6.0.4 pruning=nothing statesync_rpc_servers="" statesync_enabled=false api_enabled=true'
    ```

* Set up DNS for root domain and Hasura subdomain:
    ```
    mydomain.com.        3600 IN A     123.123.123.123
    hasura.mydomain.com. 3600 IN CNAME mydomain.com.
    ```
* Inventory file:
  - Use an appropriate password for the Hasura service with `hasura_admin_secret`.
  - Replace `archive-node.testnet.com` with your archive node address in `bigdipper_rpc_address` and `bigdipper_grpc_address`. 26657 and 9090 are the default ports for RPC and GRPC, respectively.
  - For TLS, set `bigdipper_use_tls_proxy` to `true` and a valid email for `letsencrypt_email`.


### Run the playbook 

```
ansible-playbook bigdipper.yml -i examples/inventory-bigdipper.yml -e 'target=BIG_DIPPER_ADDRESS'
```

- See the Big Dipper section in the [Playbook Variables](/docs/Playbook-Variables.md) page for additional configuration options.
- Visit the Big Dipper [docs site](https://docs.bigdipper.live/) if you want to modify the role and are looking for more information.

## Set up a Consensus Monitor

Deploy a node that monitors the consensus process on an existing chain. 

* **Inventory file:** [`inventory-consensus.yml`](inventory-consensus.yml)

### Requirements

* An online node with RPC and API endpoints available (usually ports 26657 and 1317, respectively).

### Run the playbook 

```
ansible-playbook consensus-monitor.yml -i examples/inventory-consensus.yml -e 'target=SERVER_IP_OR_DOMAIN consensus_api_node_url=NODE_ADDRESS:API_PORT consensus_rpc_node_url=NODE_ADDRESS:RPC_PORT'
```

- The consensus monitor interface can now be reached at `SERVER_IP_OR_DOMAIN`.
- The Websockets server can now be reached at `SERVER_IP_OR_DOMAIN/ws/`.

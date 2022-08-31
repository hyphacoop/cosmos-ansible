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

## Join the Theta Testnet

Set up a node to join the [theta testnet](https://github.com/cosmos/testnets/tree/master/v7-theta/public-testnet) using state sync.

* **Inventory file:** [`inventory-theta.yml`](inventory-theta.yml)
* **Chain ID:** `theta-testnet-001`
* **Gaia version:** `v7.0.0`

### Run the playbook 

```
ansible-playbook node.yml -i examples/inventory-theta.yml -e 'target=SERVER_IP_OR_DOMAIN'
```

This playbook obtains a trust block height and the corresponding hash ID from the first RPC server listed in the inventory file in order to use the state sync feature. 

## Start a Local Testnet

Set up a node with a single validator account.

* **Inventory file:** [`inventory-local.yml`](inventory-local.yml)
* **Chain ID:** `my-testnet`
* **Moniker:** `cosmos-node`
* **Gaia version:** `v7.0.0`
* **Faucet REST server**

### Run the Playbook

```
ansible-playbook node.yml -i examples/inventory-local.yml -e 'target=SERVER_IP_OR_DOMAIN'
```

- The validator address and mnemonic will be saved to `/home/gaia/.gaia/create_validator.log` in the host.
- The faucet address and mnemonic will be saved to `/home/gaia/.gaia/faucet.json` in the host.
- The faucet REST server will listen on port `8000` by default. This can be adjusted in the [faucet.service.j2](/roles/gaia/templates/faucet.service.j2) template.

## Start a Local Testnet Using a Modified Genesis File

Set up a node with a single validator account and a modified genesis file that makes the chain start at a non-zero block height. The resulting node will be similar to [this configuration](https://github.com/cosmos/testnets/tree/master/v7-theta/local-testnet).

The playbook will download the genesis file, and a private key is provided in this folder.

* **Inventory file:** [`inventory-local-genesis.yml`](inventory-local-genesis.yml)
* **Chain ID:** `theta-localnet`
* **Gaia version:** `v7.0.0`

### Run the playbook 

```
ansible-playbook node.yml -i examples/inventory-local-genesis.yml -e 'target=SERVER_IP_OR_DOMAIN'
```

## Start a Three-Node Testnet

Set up a chain with three validator nodes that have the following voting power:

| Validator moniker | Voting power | Self-delegating address                         |
| :---------------: | :----------: | ----------------------------------------------- |
|  `validator-40`   |     40%      | `cosmos1r5v5srda7xfth3hn2s26txvrcrntldjumt8mhl` |
|  `validator-32`   |     32%      | `cosmos1ay4dpm0kjmvtpug28vgw5w32yyjxa5sp97pjqq` |
|  `validator-28`   |     28%      | `cosmos1v8zgdpzqfazvk6fgwhqqhzx0hfannrajezuc6t` |

Each of the validators has a balance of 100 000 000 uatom.

- **Inventory file:** [`inventory-three-node.yml`](inventory-three-node.yml)
- **Chain ID:** `cosmos-testnet`
- **Gaia version:** `v7.0.0`

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

## Start a Single-Node Developer Testnet

Set up a host as a single-node developer testnet.

- This network is meant to be exposed to the public.
- The playbook obtains a certificate from Let's Encrypt and sets up an SSL proxy.
- Airdrop addresses can be entered in the inventory file.

* **Inventory file:** [`inventory-dev.yml`](inventory-dev.yml)
* **Chain ID:** `my-devnet`
* **Gaia version:** `v7.0.0`

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

## Set up a Hermes IBC Relayer

Set up a Hermes relayer between two chains.

* **Inventory file:** [`inventory-hermes.yml`](inventory-hermes.yml)

Follow the [Hermes IBC Relayer Setup](/docs/Hermes-Relayer-Setup.md) guide in the `docs` folder for all the requirements and steps needed to deploy the relayer. 

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

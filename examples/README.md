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

## Run a Big Dipper block explorer

Run a block explorer for your chain using the Big Dipper [software](https://bigdipper.live/) ([docs](https://docs.bigdipper.live/)).

* **Inventory file:** [`inventory-bigdipper.yml`](inventory-bigdipper.yml)

1. Install ansible-galaxy dependencies: `ansible-galaxy install -r requirements.yml`.
2. Set up a node on your Big Dipper machine. For example:
    ```
    ansible-playbook node.yml -i examples/inventory-theta.yml -e 'target=SERVER_DOMAIN'
    ```
3. Go and edit [`inventory-bigdipper.yml`](inventory-bigdipper.yml). Certain variables need to be set.
    - `hasura_admin_secret`: a random password to protect the Hasura service
    - `bdjuno_version`: a branch of [bdjuno](https://github.com/forbole/bdjuno/branches). It needs to match the chain you are deploying, for example `chains/cosmos/testnet` for the Cosmos Hub testnet (aka Theta). You can also put a commit here, but it must be a commit on the correct branch.
    - `bdui_chain`: whether the chain is `testnet` or `mainnet`
    - `chain_id`: ID of chain
    - `bigdipper_genesis_time`: the time of the chain's genesis in UTC in RFC3339 format
    - `bigdipper_genesis_height`: the height of the chain at genesis
  
    To set up TLS `bigdipper_use_tls_proxy: true` must be set, and `letsencrypt_email` must be a valid email.

    Other variables are listed [here](../roles/bigdipper/defaults/main.yml).
4. Setup DNS:
    ```
    mydomain.com.        3600 IN A     123.123.123.123
    hasura.mydomain.com. 3600 IN CNAME mydomain.com.
    rpc.mydomain.com.    3600 IN CNAME mydomain.com.
    ```
    You can configure the subdomain names if needed by setting other vars in the inventory file:
    ```yaml
    # Defaults
    hasura_host: "hasura."
    rpc_host: "rpc."
    bdui_host: ""
    ```
5. On the same machine as the blockchain node, install Big Dipper:
    ```
    ansible-playbook bigdipper.yml -i examples/inventory-bigdipper.yml -e 'target=SERVER_DOMAIN'
    ```

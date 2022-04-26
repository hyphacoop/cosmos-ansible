# Examples

Sample inventory files are provided here as reference.

After a playbook is run, you can log into a node and see if the chain is running with one of these commands:

| `use_cosmovisor` variable | `journalctl` command                |
|:-------------------------:|-------------------------------------|
|     `true` (default)      | `journalctl -fu cosmovisor.service` |
|          `false`          | `journalctl -fu gaiad.service`      |

## Join the Theta Testnet

Set up a node to join the [theta testnet](https://github.com/cosmos/testnets/tree/master/v7-theta/public-testnet) using state sync.

* **Inventory file:** [`inventory-theta.yml`](inventory-theta.yml)
* **Chain ID:** `theta-testnet-001`
* **Gaia version:** `v7.0.0`

The validator mnemonic will be saved to `/home/gaia/.gaiad/create_validator.log`.

### Requirements

- Visit a [block explorer](https://github.com/cosmos/testnets/tree/master/v7-theta/public-testnet#block-explorers) to obtain a block height roughly 1000 blocks below the current one, and its corresponding hash.

- Inventory file
  - Replace the `theta.testnet.com` address with your own in the `hosts` variable.

### Run the playbook 

Use the `--extra-vars` option to enter the trust height and hash obtained from the block explorer.

```
ansible-playbook gaia.yml -i examples/inventory-theta.yml --extra-vars "statesync_trust_height=9523000 statesync_trust_hash=02D2C347C4C51DE6E289D1CB04EF243056108621FD7CF3FD6198C0A2CDF0C8EE"
```

## Start a Local Testnet

Set up a node with a single validator account.

* **Inventory file:** [`inventory-local.yml`](inventory-local.yml)
* **Chain ID:** `my-testnet`
* **Gaia version:** `v7.0.0`

The validator mnemonic will be saved to `/home/gaia/.gaiad/create_validator.log` in the host.

### Requirements

- Inventory file
  - Replace the `testnet.com` address with your own in the `hosts` variable.

### Run the Playbook

```
ansible-playbook gaia.yml -i examples/inventory-local.yml
```

## Start a Local Testnet Using a Modified Genesis File

Set up a node with a single validator account and a modified genesis file that makes the chain start at a non-zero block height. The resulting node will be similar to [this configuration](https://github.com/cosmos/testnets/tree/master/v7-theta/local-testnet).

The playbook will download the genesis file, and a private key is provided in this folder.

* **Inventory file:** [`inventory-local-genesis.yml`](inventory-local-genesis.yml)
* **Chain ID:** `theta-localnet`
* **Gaia version:** `v7.0.0`

### Requirements

- Inventory file
  - Replace the `testnet.com` address with your own in the `hosts` variable.

### Run the playbook 

```
ansible-playbook gaia.yml -i examples/inventory-local-genesis.yml
```

## Start a Three-Node Testnet

Set up a chain with three validator nodes that have the following voting power:

| Validator moniker | Voting power | Self-delegating address                         |
|:-----------------:|:------------:|-------------------------------------------------|
|  `validator-40`   |     40%      | `cosmos1r5v5srda7xfth3hn2s26txvrcrntldjumt8mhl` |
|  `validator-32`   |     32%      | `cosmos1ay4dpm0kjmvtpug28vgw5w32yyjxa5sp97pjqq` |
|  `validator-28`   |     28%      | `cosmos1v8zgdpzqfazvk6fgwhqqhzx0hfannrajezuc6t` |

Each of the validators has a balance of 100 000 000 uatom.

- **Inventory file:** [`inventory-three-node.yml`](inventory-three-node.yml)
- **Chain ID:** `cosmos-testnet`
- **Gaia version:** `v7.0.0`

Refer to this repo's [wiki](https://github.com/hyphacoop/cosmos-ansible/wiki) to see how these accounts were created and how you can set up a genesis file and private keys if you want to further customize your testnet.

### Requirements

- Inventory file
  - Replace the addresses below with your own in the `p2p_persistent_peers` and `hosts` variables.
    - `validator-40.testnet.com`
    - `validator-32.testnet.com`
    - `validator-28.testnet.com`

### Run the Playbook

```
ansible-playbook gaia.yml -i examples/inventory-three-node.yml
```

## Start a Single-Node Developer Testnet

Set up a host as a single-node developer testnet.

* **Inventory file:** [`inventory-dev.yml`](inventory-dev.yml)
* **Chain ID:** `my-devnet`
* **Gaia version:** `v7.0.0`

### Requirements

- DNS
  - Set up an appropriate A record for Let's Encrypt.
- Inventory file
  - Replace the `dev.testnet.com` address with your own in the `hosts` variable.
  - Replace the `validator@devnet.com` address with your own in the `letsencrypt_email` variable.
  - Add the addresses of the accounts you want to airdrop tokens to in the `gaiad_airdrop_accounts` variable.
 
  
### Run the playbook 

```
ansible-playbook gaia.yml -i examples/inventory-dev.yml
```

## Start a Multi-Node Testnet

Set up multiple hosts to run a testnet with validator, sentry, and sync nodes.

* **Inventory file:** [`inventory-multi-node.yml`](inventory-dev.yml)

Follow the Multi-Node Tesnet Setup guide in the wiki for all the requirements and steps needed to deploy this network. 


## Set up a Hermes IBC Relayer

The [`hermes.yml`](/hermes.yml) playbook spins up a Hermes relayer in your inventory under the `hermes` group.

* **Inventory file:** [`inventory-hermes.yml`](inventory-hermes.yml)
* **Chain ID:** `chain-1` and `chain-2`
* **Gaia version:** `v7.0.0`

### Requirements

- DNS
  - Set up an appropriate A record for Let's Encrypt.
- Inventory file
  - Replace the `dev.testnet.com` address with your own in the `hosts` variable.
  - Replace the chain IDs in the `hermes_chains` variable with the IDs of the chains being relayed to.
  - Replace the hosts in the `hermes_chain_hostname` variables with the endpoints that Hermes will connect to.

  - Replace the `validator@devnet.com` address with your own in the `letsencrypt_email` variable.
  - Add the addresses of the accounts you want to airdrop tokens to in the `gaiad_airdrop_accounts` variable.

### Run the playbook 

`ansible-playbook hermes.yml -i inventory.yml`

After running the playbook, you must restore the key for the chains you want to relay to. Follow the instructions below to do so.

Switch to the `hermes` user.
```
su hermes
```

The key name must match the chain-ids. In the example below they are `chain-1` and `chain-2`.
```
~/bin/hermes -c ~/.hermes/config.toml keys restore chain-1 -m "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"
```

```
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
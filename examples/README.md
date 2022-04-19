# Examples

Sample inventory files are provided here as reference.

Copy the files you need to this repo's root folder, make the appropriate modifications to the inventory, and run `ansible-playbook` from there.

Whenever a playbook is run, you can check the chain is running on the host by running `journalctl -fu cosmovisor.service`, or `journalctl -fu gaiad.service` if you are not using Cosmovisor.

## Start a Local Testnet

Set up a node with a single validator account.

* **Inventory file:** [`inventory-local.yml`](inventory-local.yml)
* **Chain ID:** `my-testnet`
* **Gaia version:** `release/v7.0.0`

### Required Settings

- Host address: `root@testnet.com`  
 
  Replace `testnet.com` with your host address.


### Run the Playbook

```
ansible-playbook gaia.yml -i inventory-local.yml
```


## Start a Local Testnet Using a Modified Genesis File

Set up a node with a single validator account and a modified genesis file that makes the chain start at a non-zero block height. The resulting node will be similar to [this configuration](https://github.com/cosmos/testnets/tree/master/v7-theta/local-testnet).

The playbook will download the genesis file, and a private key is provided in this folder.

* **Inventory file:** [`inventory-local-genesis.yml`](inventory-local-genesis.yml)
* **Chain ID:** `theta-localnet`
* **Gaia version:** `release/v7.0.0`
* **Validator Mnemonic:** `junk appear guide guess bar reject vendor illegal script sting shock afraid detect ginger other theory relief dress develop core pull across hen float`

### Required Settings

- Host address: `root@testnet.com`  
 
  Replace `testnet.com` with your host address.

### Run the playbook 

```
ansible-playbook gaia.yml -i inventory-local-genesis.yml
```

## Join the Theta Testnet

Set up a node to join the [theta testnet](https://github.com/cosmos/testnets/tree/master/v7-theta/public-testnet) using state sync.

* **Inventory file:** [`inventory-theta.yml`](inventory-theta.yml)
* **Chain ID:** `theta-testnet-001`
* **Gaia version:** `release/v7.0.0`

### Required Settings

Visit a [block explorer](https://github.com/cosmos/testnets/tree/master/v7-theta/public-testnet#block-explorers) to obtain a block height roughly 1000 blocks below the current one, and its corresponding hash.

- Host address: `root@testnet.com`  
 
  Replace `testnet.com` with your host address.

### Run the playbook 

Use the `--extra-vars` option to enter the trust height and hash obtained from the block explorer.

```
ansible-playbook gaia.yml -i inventory-theta.yml --extra-vars "statesync_trust_height=9523000 statesync_trust_hash=02D2C347C4C51DE6E289D1CB04EF243056108621FD7CF3FD6198C0A2CDF0C8EE"
```

## Start a single-node developer net

Set up a host as a single-node developer testnet.

* **Inventory file:** [`inventory-dev.yml`](inventory-dev.yml)
* **Chain ID:** `my-devnet`
* **Gaia version:** `release/v7.0.0`

### Requirements

## Start a multiple-node testnet

Set up multiple hosts to start a testnet.

* **Inventory file:** [`inventory-multi-node.yml`](inventory-multi-node.yml)
* **Chain ID:** `my-testnet`
* **Gaia version:** `release/v7.0.0`

### Requirements

**DNS**

You must create a DNS entry for all subdomains of each host. If the host is `node1.testnet.com`, you will need a CNAME for:

* `rest.node1.testnet.com`
* `rpc.node1.testnet.com`
* `grpc.node1.testnet.com`
* `p2p.node1.testnet.com`

**SSL**

**Prometheus**

**Grafana**

**PANIC**

## Hermes IBC Relayer:
The playbook [`hermes.yml`](/hermes.yml) spins up Hermes relayer in your inventory under the `hermes` group.

* **Inventory file:** [`inventory-hermes.yml`](inventory-hermes.yml)
* **Chain ID:** `chain-1` and `chain-2`
* **Gaia version:** `v7.0.0`

### Required Settings
- `hermes_chains` : `hermes-chain-1` The chain ID of one of the chain being relayed to. There can be a list of chains
  - `hermes_chain_hostname:` : `chain-1.dev.testnet.com` This is the endpoint of where Hermes will connect to for `chain-1`

`ansible-playbook hermes.yml -i inventory.yml`

After running the playbook you will have to manually restore the key for the chains you want to relay to. Please run all these commands under the `hermes` user:

`su hermes`

Please note that the key name must match the chain-ids. In the example below they are `chain-1` and `chain-2`

``~/bin/hermes -c ~/.hermes/config.toml keys restore chain-1 -m "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"``

``~/bin/hermes -c ~/.hermes/config.toml keys restore chain-2 -m "abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon garage"``

After restoring the keys you can then create a client between the chains:

``~/bin/hermes -c ~/.hermes/config.toml create client chain-1 chain-2``

Once that is successful you need to create a channel between the chains:

``~/bin/hermes -c ~/.hermes/config.toml create channel --port-a transfer --port-b transfer chain-1 chain-2``

After successfully created the channel you should restart the hermes service by logging out of `hermes` and back to the `root` shell:

``systemctl restart hermes``


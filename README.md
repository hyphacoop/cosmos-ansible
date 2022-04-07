# Ansible Cosmos Network Creator

## Example

This will spin up a gaia node which will process the genesis file for the [vega testnet](https://github.com/cosmos/vega-test/blob/master/public-testnet/modified_genesis_public_testnet/genesis.json.gz)

Modify `inventory.yml` to add your own machine.

```
ansible-playbook gaia.yml -i inventory.yml
```

To override the default variables use the `--extra-vars` option

The example below will enable SSL reverse proxy, configure monitoring and configure swap
```
ansible-playbook gaia.yml -i inventory.yml --extra-vars "gaiad_use_ssl_proxy=true monitoring_prometheus=true enable_swap=true"
```

It is recommanded to use Debian 11 on your machines.

## TODOs:

- [ ] Docs!
- [ ] Block explorer
- [ ] Populate persistent_peers
- [ ] Roles extending gaiad
	- [x] sync state node
	- [ ] sentry node (needs persistent_peers)
- [ ] Firewall rules
- [ ] More Examples

## Structure

- The main role for Gaia nodes is `gaia`, most configuration is there
- Example playbook for setting up gaia in `gaia.yml`
- Example inventory file using YAML syntax in `inventory.yml`
- Main steps for setting up the node are in `roles/gaia/tasks/main.yml`
- Default variables are defined in `roles/gaia/vars/main.yml`
- Systemd services are in `roles/gaia/templates/`
- To add a variable to the .gaia config files, add it to `roles/gaia/templates/ansible_vars.json.j2` and `roles/gaia/vars/main.yml`

## Developing / Running

Prerequisits:

- Python 3
- Ansible
  - Note: Ubuntu 20.04 ships with Ansible 2.9.6 which is a buggy and can't be used in combination with a host running new systemd. It is recommanded to install via pip3 `pip3 install ansible`
- `pip3 install autopep8 yamllint pylint`

Run `./lint.sh` after making changes to detect syntax errors and normalize the formatting

## Useful variables:

- `gaia_version`: `v5.0.5` Set the tag or commit or branch to use when checking out the gaia version to compile.
- `gaia_repository`: `https://github.com/cosmos/gaia.git` The git repo to use to checkout the source tree for gaia
- `use_cosmovisor`: `true` Whether to use cosmovisor or a raw `gaiad` service
- `genesis_url`: `""` a URL to download the gzipped genesis file from
- `genesis_file`: `""` a file path (within this folder) to the genesis file to use. Note that we don't copy the file if there is an existing file that is the same length.
- `addrbook_url`: `""` a URL to download the addrbook.json file from. e.g. [via quicksync.io](https://quicksync.io/addrbook.cosmos.json)
- `addrbook_file`: `""` a file path (within this folder) to the addrbook.json file to use
- `p2p_pex`: `true` Whether p2p peer exchange is enabled
- `p2p_persistent_peers` hardcoded list of peers to connect to (e.g. for bootstrapping)
- `fast_sync`: `true`
- `enable_swap`: `false` Whether swap is enabled
- `swap_size`: `8192` Swap file size in MB (8 GB default)
- `monitoring_prometheus`: `false` Whether to configure Prometheus / Grafana monitoring
- `chain_id`: `vega-testnet` Sets the chain ID right now it is only used for displaying on Grafana
- `gaiad_use_ssl_proxy`: `false` Wheter to enable SSL proxy using nginx to gaiad endpoints
- `gaiad_api_host`: `rest` Sets the subdomain for rest API (e.g. `rest.one.theta-devnet.polypore.xyz`). Configure DNS before provisioning.
- `gaiad_rpc_host`: `rpc` Sets the subdomain for rpc (e.g. `rpc.one.theta-devnet.polypore.xyz`). Configure DNS before provisioning.
- `gaiad_grpc_host`: `grpc` Sets the subdomain for grpc (e.g. `grpc.one.theta-devnet.polypore.xyz`). Configure DNS before provisioning.
- `gaiad_p2p_host`: `p2p` Sets the subdomain for p2p (e.g. `p2p.one.theta-devnet.polypore.xyz`). Configure DNS before provisioning.
- `reboot`: `false` Whether to reboot the machine after all tasks are done (useful to make sure all services starts up and apply system updates **recommanded** for initial deployment)
- `monitoring_panic` : `false` Whether to configure PANIC monitoring
- `panic_is_validator` : `no` Tell PANIC the host is a validator

## gaia-control.py script:
This script is used to call `ansible-playbook` with different tags to run part of the `gaia` playbook.
The script takes the inventory `-i` and operation `-o` arguemnts. The inventory argument is optional and defaults to `inventory.yml` (e.g. `./gaia-control.py -o restart`)
- `./gaia-control.py -i inventory.yml -o restart` - Restarts gaiad on all nodes in inventory
- `./gaia-control.py -i inventory.yml -o stop` - Stops gaiad on all nodes in inventory
- `./gaia-control.py -i inventory.yml -o start` - Starts gaiad on all nodes in inventory
- `./gaia-control.py -i inventory.yml -o reboot` - Reboots all nodes in inventory
- `./gaia-control.py -i inventory.yml -o reset` - Runs `gaiad unsafe-reset-all` on all nodes

## Hermes IBC Relayer playbook:
This playbook `hermes.yml` spins up Hermes relayer in your inventory under the `hermes` group.

After running the playbook you will have to manually restore the key for the chains you want to relay to. Please run all these commands under the `hermes` user:

`su hermes`

Please note that the key name must match the chain-ids. In the example below they are `hermes-chain-1` and `hermes-chain-2`

``~/bin/hermes -c ~/.hermes/config.toml keys restore hermes-chain-1 -m "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art"``

``~/bin/hermes -c ~/.hermes/config.toml keys restore hermes-chain-2 -m "abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon cabbage abandon garage"``

After restoring the keys you can then create a client between the chains:

``~/bin/hermes -c ~/.hermes/config.toml create client hermes-chain-1 hermes-chain-2``

Once that is successful you need to create a channel between the chains:

``~/bin/hermes -c ~/.hermes/config.toml create channel --port-a transfer --port-b transfer hermes-chain-1 hermes-chain-2``

After successfully created the channel you should restart the hermes service by logging out of `hermes` and back to the `root` shell:

``systemctl restart hermes``

## Hermes useful variables for defining the chains:
- `hermes_chains` : `hermes-chain-1` The chain ID of one of the chain being relayed to. There can be a lits of chains
	- `hermes_chain_hostname:` : `hermes-chain-1.hermes-testnets.polypore.xyz` This is the endpoint of where Hermes will connect to for `hermes-chain-1`

Example playbook [inventory-hermes-example.yml](examples/inventory-hermes-example.yml)

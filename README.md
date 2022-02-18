# Ansible Cosmos Network Creator

## Example

This will spin up a gaia node which will process the genesis file for the [vega testnet](https://github.com/cosmos/vega-test/blob/master/public-testnet/modified_genesis_public_testnet/genesis.json.gz)

Modify `inventory.ini` to add your own machine.

```
ansible-playbook gaia.yml -i inventory.yml
```

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

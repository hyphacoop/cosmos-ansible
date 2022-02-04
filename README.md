# Ansible Cosmos Network Creator

## Example

This will spin up a gaia node which will process the genesis file for the [vega testnet](https://github.com/cosmos/vega-test/blob/master/public-testnet/modified_genesis_public_testnet/genesis.json.gz)

Modify `inventory.ini` to add your own machine.

```
ansible-playbook gaia.yml -i inventory.yml
```

## TODOs:

- [ ] Docs!
- [ ] Firewall rules
- [ ] Populate persistent_peers
- [ ] Roles extending gaiad
- [ ] Examples

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

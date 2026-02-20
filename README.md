# Ansible Cosmos Network Creator

[![Lint](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/lint.yml)
[![Join Cosmos Hub Testnet](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/test-join-hub-testnet.yml/badge.svg)](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/test-join-hub-testnet.yml)

✨ An Ansible toolkit for Cosmos networks 💫

Use this toolkit to:

- Join a testnet
- Start a local testnet
- Start a multi-node testnet

![Waterdrops feeding seedlings](images/seedling.gif)

## 🌰 Requirements 

- Python 3
- Ansible 
  - Install Ansible with `pip` and not `apt`:
    ```
    pip install ansible
    ```

## 🌱 Quick Start

To join the Cosmos Hub [Interchain Security Testnet](https://github.com/cosmos/testnets/tree/master/interchain-security):

1. Clone this repository
2. Run `ansible-galaxy install -r requirements.yml` to install dependencies 
3. Set up SSH access to the target machine
4. Run the playbook
   ```
   ansible-playbook node.yml -i examples/inventory-ics-testnet-provider.yml -e 'target=SERVER_IP_OR_DOMAIN'
   ```
5. Log into the target machine to follow the syncing process
   ```
   journalctl -fu cv-provider
   ```

## 🌳 Explore Further

- See the [examples](examples/README.md) for more command, playbook, and configuration options.
- See the [Playbook Variables Overview](docs/Playbook-Variables.md) for a list of default variables you can override with the `--extra-vars` or `-e` option.
- See the [Monitoring Setup Guide](docs/Monitoring-Setup.md) for setting up alerting and monitoring infrastructure.
- Visit the [Cosmos testnets repo](https://github.com/cosmos/testnets) for more information.

### Playbook Tags

Use `node_control.py` to run only part of the `node` playbook:

```
./node_control.py [-i inventory] [-t target] operation
```

The inventory argument is optional and defaults to `inventory.yml` (e.g. `./node_control.py restart`).

The target option is the server IP or domain.

The operation will apply to all the nodes in the inventory:
- `restart` restarts the node binary/cosmovisor service
- `stop` stops the node binary/cosmovisor service
- `start` starts the node binary/cosmovisor service
- `reboot` reboots the machine
- `reset` runs `node_binary unsafe-reset-all`

### Role Folder Structure

- The `node` role provides the core functionality of this toolkit
- Node setup: `roles/node/tasks/main.yml`
- Default variables: `roles/node/defaults/main.yml`
- Systemd services: `roles/node/templates/`
- To add a variable to the node config files, add it to:
  - `roles/node/templates/ansible_vars.json.j2`

## 🌴 Automatic Test

This repository runs the following test automatically as defined below.

### Joining the Public Testnet (weekly)

We test joining the Cosmos Hub public testnet weekly using GitHub Actions and a badge is displayed at the top of this readme.

## 🔎 Code Standards

- All Python code is formatted to PEP 8 and linted with `pylint`.
- All YAML code is linted with `yamllint`.
- See `lint.sh` and `.config/` for details.

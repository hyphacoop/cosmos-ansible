# Ansible Cosmos Network Creator

[![Lint](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/lint.yml)
[![Test Gaia Versions](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/test-gaia-versions.yml/badge.svg?branch=main)](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/test-gaia-versions.yml)
[![Test Gaia Versions with Stateful Genesis](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/test-gaia-stateful-upgrade.yml/badge.svg?branch=main)](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/test-gaia-stateful-upgrade.yml)
[![Join Public Testnet](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/test-theta-node.yml/badge.svg?branch=main)](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/test-theta-node.yml)

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

To join the Cosmos Hub [public testnet](https://github.com/cosmos/testnets/tree/master/public):

1. Clone this repository
2. Run `ansible-galaxy install -r requirements.yml` to install dependencies 
3. Set up SSH access to the target machine
4. Run the playbook
   ```
   ansible-playbook node.yml -i examples/inventory-public-testnet.yml -e 'target=SERVER_IP_OR_DOMAIN'
   ```
5. Log into the target machine to follow the syncing process
   ```
   journalctl -fu cosmovisor
   ```

Watch the video below to see the playbook in action:

[![Join the Cosmos Hub Public Testnet](https://img.youtube.com/vi/SYt0EC5pcY0/0.jpg)](https://www.youtube.com/watch?v=SYt0EC5pcY0)

## 🌳 Explore Further

- See the [examples](examples/README.md) for more command, playbook, and configuration options.
- See the [Playbook Variables Overview](docs/Playbook-Variables.md) for a list of default variables you can override with the `--extra-vars` or `-e` option.
- Visit the [Cosmos testnets repo](https://github.com/cosmos/testnets) for more information.

### Playbook Tags

Use `gaia_control.py` to run only part of the `gaia` playbook:

```
./gaia-control.py [-i inventory] [-t target] operation
```

The inventory argument is optional and defaults to `inventory.yml` (e.g. `./gaia-control.py restart`).

The target option is the server IP or domain.

The operation will apply to all the nodes in the inventory:
- `restart` restarts the gaiad/cosmovisor service
- `stop` stops the gaiad/cosmovisor service
- `start` starts thegaiad/cosmovisor service
- `reboot` reboots the machine
- `reset` runs `gaiad unsafe-reset-all`

### Role Folder Structure

- The `gaia` role provides the core functionality of this toolkit
- Node setup: `roles/gaia/tasks/main.yml`
- Default variables: `roles/gaia/defaults/main.yml`
- Systemd services: `roles/gaia/templates/`
- To add a variable to the gaia config files, add it to:
  - `roles/gaia/templates/ansible_vars.json.j2`  

## 🌴 Automatic Tests

This repository runs different tests automatically as defined below.

### Fresh State (weekly)

The fresh state test is run using GitHub Actions and results are displayed with a badge at the top of this readme.

### Mainnet exported genesis (bi-weekly)

The stateful test is run using an exported mainnet genesis file that is modified using our [tinkerer script](https://github.com/hyphacoop/cosmos-genesis-tinkerer).

Due to limited resources on GitHub Actions these tests are run on a remote virtual machine. The test results are saved to this repository's [log directory](logs/) and a badge is displayed at the top of this readme.

### Joining the Public Testnet (weekly)

We test joining the Cosmos Hub public testnet weekly using GitHub Actions and a badge is displayed at the top of this readme.

## 🔎 Code Standards

- All Python code is formatted to PEP 8 and linted with `pylint`.
- All YAML code is linted with `yamllint`.
- See `lint.sh` and `.config/` for details.

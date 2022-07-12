# Ansible Cosmos Network Creator 

[![Lint](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/lint.yml)
[![Test Gaia Versions](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/test-gaia-versions.yml/badge.svg?branch=main)](https://github.com/hyphacoop/cosmos-ansible/actions/workflows/test-gaia-versions.yml)

An Ansible toolkit for Cosmos networks. It allows your control node to:

- Start a local testnet
- Join a testnet
- Start a testnet

## Requirements 

- Python 3
- Ansible  
  You must install Ansible via `pip` instead of `apt`.
  ```
  pip install ansible
  ```
- Linting tools (optional)  
  ```
  pip install autopep8 yamllint pylint
  ```
  Run `./lint.sh` to detect syntax errors and normalize the formatting.


## How to Use

If you are setting up a single node, run:

```
ansible-playbook gaia.yml -i inventory.yml -e 'target=SERVER_IP_OR_DOMAIN'
```

If you are setting up a multi-node testnet, add the target addresses to the `hosts` section and run:

```
ansible-playbook gaia.yml -i inventory.yml
```

- Use the `--extra-vars` or `-e` option to override the default variables on the command line.
- See the [examples](examples/) for more command, playbook, and configuration options.
- Visit the [Cosmos testnets repo](https://github.com/cosmos/testnets) for more information.

<details><summary>Commonly used variables</summary>

| Variable          | Description                                                   | Example Value                        |
|-------------------|---------------------------------------------------------------|--------------------------------------|
| `target` | Target server IP/domain for Ansible | `example.com`
| `gaiad_version`    | Gaia repo tag, commit, or branch to check out and compile     | `release/v6.0.4`                     |
| `gaiad_repository` | Gaia source repo                                              | `https://github.com/cosmos/gaia.git` |
| `chain_id`        | Sets the chain ID                                             | `my-testnet`                         |
| `use_cosmovisor`  | Uses cosmovisor when `true`, raw `gaiad` service when `false` | `true`                               |
| `genesis_url` | URL to download the gzipped genesis file from | `""` |
| `genesis_file` | File path to the genesis file* | `""` |
| `addrbook_url` | URL to download the addrbook.json file from. e.g. [via quicksync.io](https://quicksync.io/addrbook.cosmos.json) | `""`  |
| `addrbook_file` | File path to the addrbook.json file to use | `""` |
| `p2p_pex` | p2p peer exchange is enabled | `true`  | 
| `p2p_persistent_peers` | list of peers to connect to | |
| `fast_sync`| Enable/disable fast sync | `true` |
| `gaiad_gov_testing` | Set minimum deposit to `1` and voting period to `5s` when `true` | `true` |
| `enable_swap` |Enable/disable swap | `false`  |
| `swap_size` |  Swap file size in MB (8 GB default) | `8192` |
| `cosmovisor_skip_backup` | Skip Cosmovisor backups | `true` |
| `monitoring_prometheus` | Configure Prometheus / Grafana monitoring | `false` |
| `gaiad_use_ssl_proxy` | Enable SSL proxy using nginx to gaiad endpoints | `false` |
| `gaiad_api_host` | Sets the subdomain for rest API (e.g. `rest.testnet.com`)** |  `rest` |
| `gaiad_rpc_host`|  Sets the subdomain for rpc (e.g. `rpc.testnet.com`)** | `rpc` |
| `reboot`| If true, reboots the machine after all tasks are done*** | `false`  |
| `monitoring_panic` | Configure PANIC monitoring | `false` |
| `panic_is_validator` | Set host as a validator for PANIC |  `no` |

*The file will not be copied if there already is an existing file with the same length.  
**Configure DNS before provisioning.  
***Useful to make sure all services start up, recommended for initial deployment.
</details>

### Running Playbook Tags

`gaia_control.py` calls `ansible-playbook` using tags to run only part of the `gaia` playbook:

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

## Folder Structure

- The `gaia` role provides the core functionality of this toolkit
- Node setup: `roles/gaia/tasks/main.yml`
- Default variables: `roles/gaia/defaults/main.yml`
- Systemd services: `roles/gaia/templates/`
- To add a variable to the gaia config files, add it to:
  - `roles/gaia/templates/ansible_vars.json.j2`  

## Automatic Tests

This repository automatically tests upgrading between Gaia versions `v6.0.4` to `v7.0.x` with a fresh state and using an modified genesis file exported from the `cosmoshub-4` mainnet.

### Fresh State (weekly)

We run the fresh state test using GitHub Actions and results are displayed with a badge at the top of this readme.

### Mainnet exported genesis (bi-weekly)

We run the stateful test using a new exported genesis then modify it using our [tinkerer script](https://github.com/hyphacoop/cosmos-genesis-tinkerer). Due to limited resources on GitHub Actions these tests are being run on a remote VM and results are in this repository's [log directory](logs/).

## Code Standards

- All Python code is formatted to PEP 8 and linted with `pylint`.
- All YAML code is linted with `yamllint`.
- See `lint.sh` and `.config/` for details.

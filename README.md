# Ansible Cosmos Network Creator

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

Set the appropriate variables in `inventory.yml` and run:

```
ansible-playbook gaia.yml -i inventory.yml
```

- Use the `--extra-vars` option to override the default variables on the command line.
- See the [examples](examples/) for more command, playbook, and configuration options.
- Visit the [Cosmos testnets repo](https://github.com/cosmos/testnets) for more information.

<details><summary>Commonly used variables</summary>

| Variable          | Description                                                   | Example Value                        |
|-------------------|---------------------------------------------------------------|--------------------------------------|
| `gaia_version`    | Gaia repo tag, commit, or branch to check out and compile     | `release/v6.0.4`                     |
| `gaia_repository` | Gaia source repo                                              | `https://github.com/cosmos/gaia.git` |
| `chain_id`        | Sets the chain ID                                             | `my-testnet`                       |
| `use_cosmovisor`  | Uses cosmovisor when `true`, raw `gaiad` service when `false` | `true`                               |
| `genesis_url` | URL to download the gzipped genesis file from | `""`
| `genesis_file` | File path to the gzipped genesis file* | `""` |
| `addrbook_url` | URL to download the addrbook.json file from. e.g. [via quicksync.io](https://quicksync.io/addrbook.cosmos.json) | `""`  |
| `addrbook_file` | File path to the addrbook.json file to use | `""` |
| `p2p_pex` | p2p peer exchange is enabled | `true`  | 
| `p2p_persistent_peers` | list of peers to connect to | |
| `fast_sync`| Enable/disable fast sync | `true` |
| `enable_swap` |Enable/disable swap | `false`  |
| `swap_size` |  Swap file size in MB (8 GB default) | `8192` |
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
./gaia-control.py [-i inventory] operation
```

The inventory argument is optional and defaults to `inventory.yml` (e.g. `./gaia-control.py restart`).

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
  and
  - `roles/gaia/vars/main.yml`

## Code Standards

- All Python code is formatted to PEP 8 and linted with `pylint`.
- All YAML code is linted with `yamllint`.
- See `lint.sh` and `.config/` for details.

## TODO:

- [ ] Docs 
- [ ] Block explorer role
- [ ] Populate persistent_peers
- [ ] Roles extending gaiad
	- [x] sync state node
	- [ ] sentry node (needs persistent_peers)
- [ ] Mainnet node
- [ ] Firewall rules
- [ ] Examples
  - [ ] Start a multi-node testnet


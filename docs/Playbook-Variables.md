# Playbook Variables Overview

You can set many variables on the command line when running a playbook.

For example, to specify a Gaia version for all the hosts in the play:
```
ansible-playbook node.yml -i examples/inventory-local.yml --extra-vars "chain_version=v7.0.2"
```

- Default values and less commonly used variables can be found in the defaults [main.yml file](/roles/gaia/defaults/main.yml).
- Update the [ansible_vars template](/roles/gaia/templates/ansible_vars.json.j2) to modify additional variables in the gaia config files.

## Target

| Variable              | Description                                               | Example Value |
|-----------------------|-----------------------------------------------------------|---------------|
| `target`              | Target server IP/domain (for single node inventory files) | `example.com` |
| `go_version`          | Golang version to install                                 | `"1.18.1"`    |
| `enable_swap`         | Enable/disable swap                                       | `false`       |
| `swap_size`           | Swap file size in MB (8 GB default)                       | `8192`        |
| `chain_use_ssl_proxy` | Enable SSL proxy for chain endpoints using Nginx*         | `false`       |
| `chain_api_host`      | Set the subdomain for REST API (e.g. `rest.testnet.com`)* | `rest`        |
| `chain_rpc_host`      | Set the subdomain for RPC (e.g. `rpc.testnet.com`)*       | `rpc`         |
| `chain_grpc_host`     | Set the subdomain for GRPC (e.g. `grpc.testnet.com`)*     | `grpc`        |
| `chain_p2p_host`      | Set the subdomain for P2P (e.g. `p2p.testnet.com`)*       | `p2p`         |
| `reboot`              | Reboot the machine after all tasks are done when `true`**  | `false`       |

*Configure DNS before provisioning.  
**Recommended for initial deployment: this makes sure all services start up and pending system updates are applied.

## Chain Binary Installation
| Variable               | Description                                                                     | Example Value                                                                      |
|------------------------|---------------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| `node_user`            | User account to install the chain binary in                                     | `gaia`                                                                             |
| `node_user_home`       | Path to the user account home                                                   | `/home/gaia`                                                                       |
| `chain_home`           | Path to chain home folder home                                                   | `/home/gaia/.gaia`                                                                 |
| `chain_home_clear`     | Clear the `chain_home` folder before install when `true`                        | `false`                                                                            |
| `node_unsafe_reset`    | Clear the chain database before install when `true`                             | `true`                                                                             |
| `chain_registry`       | Define `chain_version`, `chain_id` and `genesis_url` using the chain registry   | `https://registry.ping.pub/testnets/theta/chain.json`                              |
| `chain_version`        | Chain repo tag, commit, or branch to check out and compile                       | `v6.0.4`                                                                           |
| `chain_repository`     | URL for chain repo                                                          | `https://github.com/cosmos/gaia.git`                                               |
| `chain_binary_release` | URL of the binary to install                                                    | `https://github.com/cosmos/gaia/releases/download/v7.0.2/gaiad-v7.0.2-linux-amd64` |
| `chain_binary_source`  | Build the binary from source if set to `build`, download it if set to `release` | `build`                                                                            |
| `node_service_name`    | Chain service name when `use_cosmovisor` is `false` | `gaiad`
| `chain_bin`            | Full path for binary | `/home/gaia/go/bin/gaiad` |
| `chain_id`             | ID                                                                                                          | `my-testnet`                                                                              |
| `addrbook_url`         | URL to download the addrbook.json file from                                                                                | `"https://quicksync.io/addrbook.cosmos.json"`                                             |
| `addrbook_file`        | File path to the addrbook.json file to use                                                                                 | `"addresses.json"`                                                                        |

## Chain Configuration: `genesis.json`

| Variable                      | Description                                                                               | Example Value                                                                             |
|-------------------------------|-------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| `genesis_url`                 | URL to download the gzipped genesis file from                                             | `"https://github.com/cosmos/testnets/raw/master/v7-theta/public-testnet/genesis.json.gz"` |
| `genesis_file`                | File path to the genesis file***                                                          | `"examples/genesis-three-node.json"`                                                      |
| `chain_voting_period`         | Voting period for gov proposals                                                           | `60s`                                                                                     |
| `chain_gov_testing`           | Set minimum deposit to `1`<br> and voting period to <br>`chain_voting_period` when `true` | `false`                                                                                   |
| `chain_denom`                 | Set denom to replace `stake` with                                                         | `uatom`                                                                                   |
| `chain_create_validator`      | Create a validator when starting from fresh state                                         | `true`                                                                                    |
| `chain_gentx_validator`       | Tokens validator will self-delegate at genesis                                            | `"1000000uatom"`                                                                          |
| `chain_validator_coins`       | Funds assigned to validator through genesis | `"11000000uatom"`
| `node_keyring`                | Keyring for the validator keypair | `test` |
| `chain_airdrop`               | Airdrop tokens to accounts list when `true` | `false` |
| `chain_airdrop_coins`         | Amount to airdrop to specified accounts | `"10000uatom"` |
| `chain_airdrop_accounts`      | List of accounts to airdrop tokens to | `[address-1,address-2,address-3]`

***The file will not be copied if there already is an existing file with the same length.  

## Chain Configuration: `config.toml`

| Variable                | Example Value                                                                       |
|-------------------------|-------------------------------------------------------------------------------------|
| `fast_sync`             | `true`                                                                              |
| `rpc_port`              | `26657`                                                                             |
| `p2p_port`              | `26656`                                                                             |
| `p2p_seeds`             | `"node-id@http://seed-1.testnet.com:26656,node-id@http://seed-2.testnet.com:26656"` |
| `p2p_persistent_peers`  | `"node-id@http://p2p-1.testnet.com:26656,node-id@http://p2p-2.testnet.com:26656`"   |
| `statesync_enabled`     | `true`                                                                              |
| `statesync_rpc_servers` | `"http://rpc.sentry-1.testnet.com:26657,http://rpc.sentry-2.testnet.com"`           |

## Chain Configuration: `app.toml`

| Variable             | Example Value |
|----------------------|---------------|
| `minimum_gas_prices` | `"10uatom"`   |
| `api_enabled`        | `true`        |
| `api_port`           | `1317`        |
| `grpc_enabled`       | `true`        |
| `grpc_port`          | `9090`        |

## Chain Configuration: `client.toml`

| Variable                 | Example Value |
|--------------------------|---------------|
| `client_keyring_backend` | `os`          |
| `client_broadcast_mode`  | `sync`        |

## Faucet

| Variable              | Description                                          | Example Value  |
|-----------------------|------------------------------------------------------|----------------|
| `faucet_enabled`      | Create faucet account and install REST server for it | `true`         |
| `faucet_version`      | Cosmos REST faucet version to install                | `v0.2.1`       |
| `faucet_service_name` | Service name for faucet REST server                  | `token-faucet` |

## Cosmovisor

| Variable                 | Description                                                            | Example Value |
|--------------------------|------------------------------------------------------------------------|---------------|
| `use_cosmovisor`         | Use cosmovisor service when `true`, standalone binary one when `false` | `true`        |
| `cosmovisor_skip_backup` | Skip Cosmovisor backups                                                | `true`        |

## Monitoring and Alerting

| Variable                | Description                               | Example Value                                           |
|-------------------------|-------------------------------------------|---------------------------------------------------------|
| `monitoring_prometheus` | Configure Prometheus / Grafana monitoring | `false`                                                 |
| `monitoring_panic`      | Configure PANIC monitoring                | `false`                                                 |
| `panic_ssh_url`         | User and address for PANIC server         | `root@monitor.polypore.xyz`                             |
| `panic_config_file`     | Path on PANIC server                      | `/home/panic/panic_cosmos/config/user_config_nodes.ini` |
| `panic_is_validator`    | Set host as a validator for PANIC         | `no`                                                    |

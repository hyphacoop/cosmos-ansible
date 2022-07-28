# Playbook Variables Overview

You can set many variables on the command line when running a playbook.

For example, to specify a Gaia version for all the hosts in the play:
```
ansible-playbook gaia.yml -i examples/inventory-local.yml --extra-vars "chain_version=v7.0.2"
```

| Variable                 | Description                                                                       | Example Value                                                                                       |
|--------------------------|-----------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| `target` | Target server IP/domain | `example.com` |
| `chain_registry` | When set it will automatically define `chain_version`, `chain_id` and `genesis_url` variables from the chain registry file | `https://registry.ping.pub/testnets/theta/chain.json` |
| `chain_version`          | Gaia repo tag, commit, or branch to check out and compile                         | `v6.0.4`                                                                                            |
| `chain_repository`       | Gaia source repo                                                                  | `https://github.com/cosmos/gaia.git`                                                                |
| `chain_id`               | Sets the chain ID                                                                 | `my-testnet`                                                                                        |
| `use_cosmovisor`         | Uses cosmovisor when `true`, raw `gaiad` service when `false`                     | `true`                                                                                              |
| `genesis_url`            | URL to download the gzipped genesis file from                                     | `"https://github.com/cosmos/testnets/raw/master/v7-theta/public-testnet/genesis.json.gz"` |
| `genesis_file`           | File path to the genesis file*                                                    | `"examples/genesis-three-node.json"`                                                                |
| `addrbook_url`           | URL to download the addrbook.json file from                                       | `"https://quicksync.io/addrbook.cosmos.json"`                                                       |
| `addrbook_file`          | File path to the addrbook.json file to use                                        | `"addresses.json"`                                                                                  |
| `p2p_pex`                | p2p peer exchange is enabled                                                      | `true`                                                                                              |
| `p2p_persistent_peers`   | list of peers to connect to                                                       | "`9e3598aa@peer-1.testnet.com:26656,6bf6361@peer-2.testnet.com:26656`"                              |
| `fast_sync`              | Enable/disable fast sync                                                          | `true`                                                                                              |
| `chain_gov_testing`      | Set minimum deposit to `1` and voting period to `chain_voting_period` when `true` | `true`                                                                                              |
| `chain_voting_period`    | Voting period for gov proposals                                                   | `60s`                                                                                               |
| `enable_swap`            | Enable/disable swap                                                               | `false`                                                                                             |
| `swap_size`              | Swap file size in MB (8 GB default)                                               | `8192`                                                                                              |
| `cosmovisor_skip_backup` | Skip Cosmovisor backups                                                           | `true`                                                                                              |
| `monitoring_prometheus`  | Configure Prometheus / Grafana monitoring                                         | `false`                                                                                             |
| `gaiad_use_ssl_proxy`    | Enable SSL proxy using nginx to gaiad endpoints                                   | `false`                                                                                             |
| `gaiad_api_host`         | Sets the subdomain for rest API (e.g. `rest.testnet.com`)**                       | `rest`                                                                                              |
| `gaiad_rpc_host`         | Sets the subdomain for rpc (e.g. `rpc.testnet.com`)**                             | `rpc`                                                                                               |
| `reboot`                 | If true, reboots the machine after all tasks are done***                          | `false`                                                                                             |
| `monitoring_panic`       | Configure PANIC monitoring                                                        | `false`                                                                                             |
| `panic_is_validator`     | Set host as a validator for PANIC                                                 | `no`                                                                                                |

- *The file will not be copied if there already is an existing file with the same length.  
- **Configure DNS before provisioning.  
- ***Recommended for initial deployment: this makes sure all services start up and pending system updates are applied.

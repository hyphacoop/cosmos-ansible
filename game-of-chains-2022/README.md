# Game of Chains Playbooks

Inventory files are provided here as reference and to help participants join different chains.

## Join the Provider Chain

* **Inventory file:** [`provider/provider-join.yml`](provider/provider-join.yml)
* Binary: `gaiad`
  * [Linux amd64 build](https://github.com/hyphacoop/ics-testnets/raw/goc-day-1/game-of-chains-2022/provider/gaiad)
  * [glnro/ics-sdk45 branch](https://github.com/jtremback/gaia/tree/glnro/ics-sdk45)
  * Commit 84a33e4910abcc157f3333a70918a4fd6dc4cf6d
* Binary SHA256: `02e3d748d851f6ce935f1074307ebfa83f40a417ad6668928f7aa28d4149c671`
* Chain ID: `provider`
* Denom: `uprov`
* Bech32 prefix: `cosmos`

Run the playbook:
```
ansible-playbook node.yml -i game-of-chains-2022/provider/provider-join.yml -e 'target=SERVER_IP_OR_DOMAIN node_key_file=<JSON file path> priv_validator_key_file=<JSON file path>"'
```

After the play has finished running, run `journalctl -fu cv-provider` to check the output of cosmovisor, or `journalctl -fu provider` if you set `use_cosmovisor` to `false`.


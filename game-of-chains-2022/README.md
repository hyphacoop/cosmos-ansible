# Game of Chains Playbooks

Inventory files are provided here as reference and to help participants join different chains.

These playbooks have been tested with Ubuntu 22.10.

## Join the Provider Chain

* **Inventory file:** [`provider-join.yml`](provider-join.yml)
* Binary: `gaiad`
  * [Linux amd64 build](https://github.com/hyphacoop/ics-testnets/raw/main/game-of-chains-2022/provider/gaiad)
  * [glnro/ics-sdk45 branch](https://github.com/cosmos/gaia/tree/glnro/ics-sdk45)
  * Commit 199f728fc6394bdc3f8816fdb906e12f37493bc5
* Binary SHA256: `d1dc6d31671a56b995cc8fab639a4cae6a88981de05d42163351431b8a6691cf`
* Chain ID: `provider`
* Denom: `uprov`
* Bech32 prefix: `cosmos`

Run the playbook:
```
ansible-playbook node.yml -i game-of-chains-2022/provider-join.yml -e 'target=SERVER_IP_OR_DOMAIN node_key_file=<JSON file path> priv_validator_key_file=<JSON file path>'
```

After the play has finished running, run `journalctl -fu cv-provider` to check the output of cosmovisor, or `journalctl -fu provider` if you set `use_cosmovisor` to `false`.


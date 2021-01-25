# Crypto SAK

Crypto SAK is a tool for exporting cryptocurrency transactions to [CoinTracking](https://cointracking.info/) format.

## Usage

Run `help` to see the list of supported commands:

```shell
swift run CryptoSAK help
```

```
algorand-statement               Export Algorand transactions
ethereum-ico-statement           Export Ethereum-based ICO contribution, trade and payout transactions
ethereum-statement               Export Ethereum transactions
ethereum-tokens-statement        Export Ethereum-based token transactions
gate-billing-statement           Convert Gate.io billing history
hashgraph-statement              Export Hashgraph transactions
idex-balance-statement           Convert IDEX balance history
idex-trade-statement             Convert IDEX trade history
kusama-extrinsics-statement      Export Kusama extrinsics
kusama-rewards-statement         Export Kusama rewards history
polkadot-extrinsics-statement    Export Polkadot extrinsics
polkadot-rewards-statement       Export Polkadot rewards history
tezos-statement                  Export Tezos operations
```

Run `help <command>` to see the information about a specific command:

```shell
swift run CryptoSAK help ethereum-statement
```

## Disclaimer

The tool is not tested beyond my own personal use. No correctness guarantees are given. Service APIs might change and the tool will no longer be able to export transactions.

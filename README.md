# Crypto SAK

Crypto SAK is a tool for exporting cryptocurrency transactions to [CoinTracking](https://cointracking.info/) format.

## Blockchains

### Algorand statement

Takes into account fees, staking rewards and close remainders.

```shell
swift run CryptoSAK algorand-statement <address> --known-transactions <known-transactions-csv>
```

Arguments:

1. `address` - Algorand address

Options:

1. `known-transactions-csv` - Path to a CSV file with a list of known transactions (allows to overrride the transaction type and add a custom description).
    - Format (no header row): `<transaction-id>,<transaction-type>,<description>`

### Ethereum ICO statement

This command will try to match contributions with payouts from the ICO address. A trade and withdrawal  from the ICO address will be created for every payout.

```shell
swift run CryptoSAK ethereum-ico-statement <ico-csv>
```

Arguments:

1. `ico-csv` - Path to a CSV file with information about ICO
    - Format (single row): `<ico-name>,<token-symbol>,<contribution-transaction-hash-1>,<contribution-transaction-hash-2>,...`

### Ethereum statement

Takes into account internal transactions, cancelled transactions and all fees.

```shell
swift run CryptoSAK ethereum-statement <address> --start-date <start-date>
```

Arguments:

1. `address` - Ethereum address

Options:

1. `--start-date` - Oldest date from which transactions will be exported
    - Format: `YYYY-MM-DD`

### Ethereum tokens statement

Takes into account cancelled transactions and all fees.

```shell
swift run CryptoSAK ethereum-tokens-statement <address> --token-list <tokens-csv> --start-date <start-date>
```

Arguments:

1. `address` - Ethereum address

Options:

1. `--tokens-csv` - Path to a CSV file with a list of tokens to be exported (other tokens will be ignored)
   - Format (no header row): `<token-contract-address>,<token-symbol>`
2. `--start-date` - Oldest date from which transactions will be exported
   - Format: `YYYY-MM-DD`

### Hashgraph ICO statement

```shell
swift run CryptoSAK hashgraph-ico-statement <account> <ico-csv>
```

Arguments:

1. `account` - Hashgraph account ID
2. `ico-csv` - Path to a CSV file with information about ICO
    - Format (no header row): `<ico-name>,<contribution-amount>,<contribution-currency>,<sender-account-ID>`
    - Each row is a separate ICO

### Hashgraph statement

```shell
swift run CryptoSAK hashgraph-statement <account>
```

Arguments:

1. `account` - Hashgraph account ID

### Tezos statement

```shell
swift run CryptoSAK tezos-statement <account> --delegate-list <delegates-csv> --start-date <start-date>
```

Arguments:

1. `account` - Tezos account

Options:

1. `--delegates-csv` - Path to a CSV file with a list of delegate payout accounts (for detection of baking rewards)
   - Format (no header row): `<delegate-payout-account>,<delegate-name>`
2. `--start-date` - Oldest date from which operations will be exported
   - Format: `YYYY-MM-DD`

## Exchanges

### Gate.io billing statement

Takes into account all fees.

```shell
swift run CryptoSAK gate-billing-statement <billing-csv>
```

Arguments:

1. `billing-csv` - Path to Gate.io billing CSV file

### IDEX balance statement

```shell
swift run CryptoSAK idex-balance-statement <balance-tsv>
```

Arguments:

1. `balance-tsv` - Path to a TSV file with IDEX balance history
    - Balance history should be manually copied from the website. Open balance history page, select all, and copy to a tab delimited TSV file.
    - Append the transaction hash to every row (Ethereum withdrawal fees will reported).
    - Format (with header row): `<date>   <asset>	<type>	<name>	<amount> <status>	<transaction>`

### IDEX trade statement

Takes into account trade and gas fees.

```shell
swift run CryptoSAK idex-trade-statement <trades-csv>
```

Arguments:

1. `trades-csv` - Path to CSV file with IDEX trade history

## Disclaimer

The tool is not tested beyond my own personal use. No correctness guarantees are given. Service APIs might change and the tool will no longer be able to export transactions.

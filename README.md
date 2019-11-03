# Crypto SAK

Crypto SAK is a tool for exporting cryptocurrency transactions to [CoinTracking](https://cointracking.info/) format.

## Ethereum ICO

This command will try to match contributions with payouts from the ICO address. A trade and withdrawal  from the ICO address will be created for every payout.

```shell
swift run CryptoSAK ethereum-ico <ico_csv>
```

Arguments:

1. `ico_csv` - Path to a CSV file with information about ICO
    - Format (single row): `<ico_name>,<token_symbol>,<contribution_transaction_hash_1>,<contribution_transaction_hash_2>,...`

## Ethereum statement

Takes into account internal transactions, cancelled transactions and all fees.

```shell
swift run CryptoSAK ethereum-statement <address> --start-date <start_date>
```

Arguments:

1. `address` - Ethereum address
2. `start_date` - **[Optional]** Oldest date from which transactions will be exported
    - Format: `YYYY-MM-DD`

## Ethereum tokens statement

Takes into account cancelled transactions and all fees.

```shell
swift run CryptoSAK ethereum-tokens-statement <address> --token-list <tokens_csv> --start-date <start_date>
```

Arguments:

1. `address` - Ethereum address
2. `tokens_csv` - **[Optional]** Path to a CSV file with a list of tokens to be exported (other tokens will be ignored)
   - Format (no header row): `<token_contract_address>,<token_symbol>`
3. `start_date` - **[Optional]** Oldest date from which transactions will be exported
   - Format: `YYYY-MM-DD`

## Gate.io billing statement

Takes into account all fees.

```shell
swift run CryptoSAK gate-billing-statement <billing_csv>
```

Arguments:

1. `billing_csv` - Path to Gate.io billing CSV file

## IDEX balance statement

```shell
swift run CryptoSAK idex-balance-statement <balance_tsv>
```

Arguments:

1. `balance_tsv` - Path to a TSV file with IDEX balance history
    - Balance history should be manually copied from the website. Open balance history page, select all, and copy to a tab delimited TSV file.

## IDEX trade statement

Takes into account trade and gas fees.

```shell
swift run CryptoSAK idex-trade-statement <trades_csv>
```

Arguments:

1. `trades_csv` - Path to CSV file with IDEX trade history

## Tezos statement

```shell
swift run CryptoSAK tezos-statement <account> --delegate-list <delegates_csv> --start-date <start_date>
```

Arguments:

1. `account` - Tezos account
2. `delegates_csv` - **[Optional]** Path to a CSV file with a list of delegate payout accounts (for detection of baking rewards)
   - Format (no header row): `<delegate_payout_account>,<delegate_name>`
3. `start_date` - **[Optional]** Oldest date from which operations will be exported
   - Format: `YYYY-MM-DD`

## Disclaimer

The tool is not tested beyond my own personal use. No correctness guarantees are given. Service APIs might change and the tool will no longer be able to export transactions.

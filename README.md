# Crypto SAK

Crypto SAK is a tool for exporting cryptocurrency transactions to CoinTracking format.

## Ethereum statement

```shell
swift run CryptoSAK ethereum-statement <address>
```

Arguments:

1. Ethereum address


## Ethereum tokens statement

```shell
swift run CryptoSAK ethereum-tokens-statement <address> --token-list <tokens_csv>
```

Arguments:

1. Ethereum address
2. [Optional] Path to CSV file
   - List of tokens to be exported (allows to ignore spam tokens)
   - Format (no header row): `<token_contract_address>,<token_symbol>`

## Ethereum ICO (experimental)

```shell
swift run CryptoSAK ethereum-ico <ico_csv>
```

Arguments:

1. Path to CSV file
    - File with one row of information about ICO
    - Format (no header row): `<ico_name>,<token_symbol>,<contribution_transaction_hash_1>,<contribution_transaction_hash_2>,...`

## Tezos statement

```shell
swift run CryptoSAK tezos-statement <account> --delegate-list <delegates.csv> --start-date <YYYY-MM-DD>
```

Arguments:

1. Tezos account
2. [Optional] Path to CSV file
   - List of delegate payout accounts for detection of baking rewards
   - Format (no header row): `<delegate_payout_account>,<delegate_name>`
3. [Optional] Calendar date in ISO format: `YYYY-MM-DD`

## Disclaimer

The tool is not tested beyond my own personal use. Service APIs might change and the tool will no longer be able to export transactions.

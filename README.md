# Crypto SAK

Crypto SAK is a tool for exporting cryptocurrency transactions to CoinTracking format.

Currently supported exports:

* Ethereum transaction fees
```
swift run CoinTrackingExporter ethereum-fees <address>
```

* Ethereum ICO (experimental)*
```
swift run CoinTrackingExporter ethereum-ico <input_csv>
```

* Ethereum balance
```
swift run CoinTrackingExporter ethereum-balance <address>
```

\* Requires an input CSV file with the following format: `<ico_name>,<token_symbol>,<contribution_transaction_hash_1>,<contribution_transaction_hash_2>,...`

## Disclaimer

The tool is not tested beyond my own personal use. Service APIs might change and the tool will no longer be able to export transactions.

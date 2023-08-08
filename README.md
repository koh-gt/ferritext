# ferritext
Ferritext is a Powershell script to send text inscriptions on the Ferrite blockchain.  
This utilises the previously disabled op_return function in Bitcoin.  

## Description
#### A raw transaction is created with data encoded in hexadecimal.  
```bash
createrawtransaction "[]" '{"data":"deadbeef"}'
```
> 0200000000010000000000000000066a04deadbeef00000000  
#### Fund the transaction using the secret key.
```bash
# Executing command using "" wallet
fundrawtransaction 0200000000010000000000000000066a04deadbeef00000000
```
> {
>  "hex": "0200000001a6d679856ae570f7c062bc39b648f61acce89dfc3e15242a363b55f8a7e0b8fd0100000000feffffff020000000000000000066a04deadbeef6a33f853020000001600145723b2b3d3104a8cbef4e7f7ff59a36624d2874e00000000",
>  "fee": 0.00000125,
>  "changepos": 1
>}  
#### Sign the transaction using the public key.
```bash
signrawtransactionwithwallet 0200000001a6d679856ae570f7c062bc39b648f61acce89dfc3e15242a363b55f8a7e0b8fd0100000000feffffff020000000000000000066a04deadbeef6a33f853020000001600145723b2b3d3104a8cbef4e7f7ff59a36624d2874e00000000
```
> {
>  "hex": "02000000000101a6d679856ae570f7c062bc39b648f61acce89dfc3e15242a363b55f8a7e0b8fd0100000000feffffff020000000000000000066a04deadbeef6a33f853020000001600145723b2b3d3104a8cbef4e7f7ff59a36624d2874e02473044022068f7d57130f33fa643093a1dba64c97292b444ec3442269da1499cfcb23cfc6f022052d5f91284b70141f63a7d7c96e0cbde7c2e23b76067dff9041ead8e5b27f1f701210343db7639b716fb9c7d61fbaf924ca32c990e2f91764cbe5a6b3285cd5b024a2a00000000",
>  "complete": true
>}  
#### Broadcast the transaction.
```bash
sendrawtransaction 02000000000101a6d679856ae570f7c062bc39b648f61acce89dfc3e15242a363b55f8a7e0b8fd0100000000feffffff020000000000000000066a04deadbeef6a33f853020000001600145723b2b3d3104a8cbef4e7f7ff59a36624d2874e02473044022068f7d57130f33fa643093a1dba64c97292b444ec3442269da1499cfcb23cfc6f022052d5f91284b70141f63a7d7c96e0cbde7c2e23b76067dff9041ead8e5b27f1f701210343db7639b716fb9c7d61fbaf924ca32c990e2f91764cbe5a6b3285cd5b024a2a00000000
```
> a501fc550b4e4f6e0b6c24c90e2314cc67190f0aebd9f71231ef6e99b8995b4b

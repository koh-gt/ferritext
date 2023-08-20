# ferritext
Ferritext is a Powershell script to send text inscriptions on the Ferrite blockchain.  
This utilises the previously disabled op_return function in Bitcoin.  

## Information
Ferrite Core constitutes a decentralized blockchain employing proof-of-work, providing FEXT with an integrated anonymous and censorship-resistant messaging layer.

### Decentralized Blockchain Infrastructure
Ferrite operates on a decentralized blockchain infrastructure, where transactions and messaging are recorded in a distributed and immutable ledger. This network infrastructure ensures security, transparency, and resilience against censorship attempts since a copy of all blockchain data is synchronised and stored on every node of the Ferrite network.

### FEXT Integration
Privacy laws vary across countries and finding common ground to establish a consistent framework for privacy protection on a global scale is challenging. To address the issues surrounding communication privacy, FEXT (Ferritext Messenger) delivers text messaging to the blockchain, by building upon the cryptocurrency infrastructure of Ferrite by extending its capabilities beyond currency transactions. FEXT represents the vision of harnessing the blockchain for communications privacy and freedom through the Ferrite ecosystem.

### Anonymous Messaging Layer
The Ferrite Coin network offers an integrated messaging layer that allows users to communicate privately and anonymously. Messages sent through this layer are encrypted and stored on the blockchain, ensuring that users have control over their identity data. The use of cryptographic techniques guarantees the confidentiality of messages.

This anonymity is crucial for the freedom of fostering open discourse, promoting diversity of thought, and ensuring the free flow of information in society to promote open communication without the fear of censorship, retaliation, or legal repercussions by governments or central authorities. Anonymity is especially valuable in environments where freedom of expression is restricted, where external entities intend to trace information sources. 

### Censorship resistant
In some parts of the world, governments suppress freedom of speech to control dissent and maintain power, a challenge for individuals and organizations striving for open dialogue. Open dialogue is necessary for informed decision-making during elections, policy debates, and other civic activities by encouraging the coexistence of diverse viewpoints and opinions. FEXT allows users to raise awareness about issues and challenge potential abuses of authority by facilitating the coexistence of diverse viewpoints and opinions as a check on authoritarian power. By catalysing institutional accountability, the free exchange of information not excluding public discoveries/intellectual property, as well as the unrestricted expression of culturally diverse perspectives, FEXT can open a gateway to observe the unfiltered and unrestricted insights of current social expression. 

The messaging layer is designed to be censorship-resistant, such that external entities, including governments or central authorities, are unable to easily block, control, or censor FEXT messages. 

## Technical Description
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

![ferrite_BANNER_flow_red3k1ka](https://github.com/koh-gt/ferritext/assets/101822992/2d2c5762-49c8-4bc0-b6a8-ece36e80d6e2)

# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js


## DOMAIN_SEPERATOR: 
EIP-712 defines a domain separator to separate messages from different dApps or contracts. IT  defines a structured way to encode data for signing and verifying off-chain messages. used for gasless transactions, meta-transactions  and other signature-based actions.

benifets

1. It ensures that signed messages are tightly coupled to the specific domain (i.e., the smart contract, chain, and purpose).

2. Prevents replay attacks across different domains by providing unique identification for the contract and chain.

```
       DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
name =  smart contract name        

```

# Permit Function:  
Protect from Replay Attack Protection, domain specific signing (DOMAIN_SEPERATOR),
ECDSA verification (ecrecover).

Benefits of permit
Gasless Approval, Allows single-transaction workflows for token approvals and usage( like token swaps)
It complinace with EIP-2612 , enabling seamless integration with wallets and dapp that support this standard.

```
        abi.encodePacked(
            '\x19\x01',
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
        )
```

EIP-191 (\x19\x01):
this ensure message is signed uniquely for ethereum chain.

PERMIT_TYPEHASH: represent Permit function structure.

DOMAIN_SEPARATOR: ties the signature to a specific contract. prevent cross-chain, cross-contract reply attack,



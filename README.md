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

## mintFee

it mints the adition liquidity propotional to exisiting liqudity( totalSupply) and growth of the pool (rootK - rootKLast).
```
numerator = totalSupply * (rootK - rootKLast);
denominator = (rootK * 5) + rootKLast;

```

rootK * 5 ensures that the protocol only takes a small fraction (1/6th) of the growth in rootK as fees.

the factor of 5 in the denomicator effectively allocates , 5 parts of the growth to
the liqudity providers and 1 part (1/6th of total growth) to the protocol as fees.

```
else if (_kLast != 0) {
    kLast = 0;
}

```
if kLast is non-zero and fee is disabled now. kLast is reset to 0. 
this ensure fee mechanism does not accumulate unintended state. 
kLast is zero mean new pair is deployed and no trade or fee minting happend or kLast reset to zero.

for first liqudity minting no fee would be minted as pool has not seen any growth.
it is by design of the Fundswap.

# swap Function

token swaping: while swaping the token one of the two thing happen to each of the token in the pair 

1. The pool had a net increase in the amount of a particular token.

2. The pool had a net decrease (or no change) in the amount of a particular token.

currentContractBalanceX > previousContractBalanceX - _amountXOut

if above is true i.e. liquidity has been added if not ternary operator returns zero.

calculating amountIn 

amountXIn = balanceX - (_reserveX - amountXout)

NOTE: amountXIn can not be negative

Suppose our previous balance was 10, amountOut is zero, and currentBalance is 12. That means the user deposited 2 tokens. amountXIn will be 2.

Suppose our previous balance was 10, amountOut is 7, and currentBalance is 3. amountXIn will be 0.

Suppose our previous balance was 10, amountOut is 7, and currentBalance is 2. amountXIn will still be zero, not -1. It is true that the pool had a net loss of 8 tokens, but amountXIn cannot be negative.

Suppose our previous balance was 10, and amountOut is 6. If the currentBalance is 18, then the user “borrowed” 6 tokens but paid back 8 tokens.

conclusion: amount0In , amnount1In will refelect net gain if there was net gain for the tokoen , and zero if there was net loss of the token.


## Balancing XY = K

 uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');

 Uniswap V2 charges a hardcoded 0.3% per swap on amountIn. 

 K is not really constant

 in constant product formula of AMM constant is little misleading
 It is by Fastswap design of someone donated tokens to the pool and changed the value of K, we wouldn’t want to stop them because they made us liquidity providers richer.

 ## Accounting for fees   
Fastswap only charge only amountIn . 

Suppose we put in 1000 of token0 and remove 1000 of token1. We would need to pay a fee of 3 on token0 and no fee on token1.

Suppose we borrow 1000 of token0 and do not borrow token1. We are going to have to put 1000 of token0 back in, and we will have to pay a 0.3% fee on that — 3 of token0.

NOTE: if we flash borrow one of the tokens, it results in the same fee as swapping that token for the same amount. if you don't put tokens in there is no way for you
tok borrow or swap.

Safty checks:
there are two things that can go wrong

1. the amountIn is not enfore to be optimal, so the user might overpay for the swap
2. amountOut has no flexibility as it is supplied as param argument. if amountIn turn out not be sufficient to amountOut, the transaction will revert and gas will
be wasted.

# Flash Borrowing

the data  that should be provided with the funcion call is passed
as argument to function that implements IFastswapV2Callee.  The function uniswapV2Call must pay back the flash loan plus the fee or the transaction will revert.
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');

For MOre INfo: https://www.rareskills.io/post/uniswap-v2-swap-function

# burn liquidity
https://www.rareskills.io/post/uniswap-v2-mint-and-burn


# first time liquidity minting when pool is empty








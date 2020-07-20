# REVV - Animoca Brands’ ERC-20 Utility Token

Animoca Brands is developing the F1® Delta Time blockchain game platform (partially available in beta stage), and a new blockchain game based on MotoGP (coming soon).

The motorsport experiences provided in F1® Delta Time and MotoGP will be connected by a  shared economy, made possible by the ERC-20 fungible token REVV. The REVV token is designed to be the currency of purchase, utility and action in F1® Delta Time and MotoGP, and, potentially, other titles.  

Having one utility token for multiple titles will encourage players to explore the other games, and unlocks the possibility that any content or tokens they own will increase in value as the larger token ecosystem expands. This design leverages the blockchain asset concept of interoperability, where tokens can be utilised across multiple connected titles. 

## The Anatomy of the REVV ERC-20

The REVV token is a fungible token that exists on the Ethereum blockchain. A fungible token is an asset that is interchangeable with tokens of the same type - so one REVV token always has the same value as any other single REVV token.
 
REVV is a standard Ethereum ERC-20 token with commonly used interfaces. It also contains a whitelisted operators feature which enables meta-transactions without requiring pre-approval. Concretely, it provides the opportunity for players to pay for transaction fees with a currency other than ETH.

REVV implements ERC165 introspection standard. The following ERC165 interfaces are supported:

| Interface | Specification | ERC165 Interface Id(s) |
| :----     | :---          | :---                   |
| ERC-165   | https://eips.ethereum.org/EIPS/eip-165 | `0x01ffc9a7` |
| ERC-20    | https://eips.ethereum.org/EIPS/eip-20 | `0x36372b07` |
| ERC-20 Detailed   | https://github.com/animocabrands/ethereum-contracts-erc20_base/blob/v3.0.0a/contracts/token/ERC20/IERC20Detailed.sol | `0xa219a025` name():`0x06fdde03` symbol(): `0x95d89b41` decimals(): `0x313ce567` |
| ERC-20 Allowance   | https://github.com/animocabrands/ethereum-contracts-erc20_base/blob/v3.0.0a/contracts/token/ERC20/IERC20Allowance.sol | `0x9d075186` |


### Core Token Feature

REVV supports the standard features of an ERC-20 token, as described by the interfaces “ERC-20” and “ERC-20 Detailed” in the table above. The “ERC-20 Allowance” brings some usability for managing allowances. 

### Whitelisted Operators

Using an ERC-20 to make a payment through a smart contract requires an initial additional user transaction to explicitly give the contract some allowance of this ERC-20. 

The REVV token smart contract can whitelist other contracts in its ecosystem, allowing them to implicitly manage tokens for users without the allowance step, enhancing the base user experience.

To manage adding and removal of whitelisted operators, the REVV contract has an owner account. Ownership is transferable and renounceable. Animoca Brands maintains ownership of the REVV owner account and will apply changes of whitelisted operators from time to time.

It is essential that only trusted contracts obtain the status of whitelisted operators. Animoca Brands will determine which contracts within the ecosystem are suitable for being used as REVV whitelisted operators. There are two main types of ecosystem whitelisted operators: 
- Purchase contracts which support payments with REVV.
- Contracts with REVV-based meta-transactions which allow the users to pay the transaction gas with REVV instead of ETH. 

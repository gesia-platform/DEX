# DexContractNew - Decentralized Exchange for ERC1155 Tokens

## Overview

DexContractNew is a decentralized exchange (DEX) smart contract designed for trading ERC1155 tokens. It provides a secure platform for users to buy and sell NFTs and multi-tokens.

## Key Features

### 1. Order Creation

- **Bid Orders**: Orders to purchase specific tokens by depositing ETH
- **Ask Orders**: Orders to sell owned tokens

### 2. Order Execution

- **Standard Execution**: Execute trades by matching bid/ask orders
- **Execution with Refund**: Execute trades with refund of excess amounts when price differences occur

### 3. Order Cancellation

- Cancel unfulfilled orders and return deposited assets

### 4. Access Control

- Only accounts with Operator privileges can execute orders
- Regular users can only create/cancel orders

## Contract Structure

### Order Struct

```solidity
struct Order {
    address user;                   // Order creator
    address tokenContractAddress;   // ERC1155 token contract address
    uint256 tokenId;                // Token ID
    uint256 amount;                 // Trading quantity
    uint256 price;                  // Price per unit (wei)
    bool isBuyOrder;                // Whether it's a buy order
    bool isActive;                  // Order activation status
}
```

### Trading Limits

- **Minimum Amount**: 1
- **Maximum Amount**: 1,000
- **Minimum Price**: 1 wei
- **Maximum Price**: 10,000,000,000 wei

## Function Descriptions

### 1. bidOrder (Create Buy Order)

```solidity
function bidOrder(address token_contract_address, uint256 token_id, uint256 amount, uint256 price) public payable
```

- Create a buy order by depositing ETH
- `msg.value` must exactly match `amount * price`

### 2. askOrder (Create Sell Order)

```solidity
function askOrder(address token_contract_address, uint256 token_id, uint256 amount, uint256 price) public
```

- Create a sell order by depositing tokens to the contract
- Token approval required beforehand

### 3. executeOrder (Execute Orders)

```solidity
function executeOrder(uint256[] calldata bidOrderIds, uint256[] calldata askOrderIds, uint256[] calldata orderAmounts) public
```

- Only callable by Operators
- Execute trades by matching bid/ask orders

### 4. executeOrderWithRefund (Execute Orders with Refund)

```solidity
function executeOrderWithRefund(uint256[] calldata bidOrderIds, uint256[] calldata askOrderIds, uint256[] calldata orderAmounts) public
```

- Refund excess amounts to buyers when price differences occur

### 5. cancelOrder (Cancel Orders)

```solidity
function cancelOrder(uint256[] memory orderIds) public
```

- Order creators or Operators can cancel orders
- Return deposited assets

## Events

- `BidEvent`: Emitted when a buy order is created
- `AskEvent`: Emitted when a sell order is created
- `CancelEvent`: Emitted when an order is cancelled
- `TradeExecuteEvent`: Emitted when a trade is executed
- `TradeExecuteInRefundEvent`: Emitted when a trade with refund is executed

## Security Features

- **ReentrancyGuard**: Prevents reentrancy attacks
- **SafeMath**: Prevents overflow/underflow
- **Operator Permissions**: Restricts order execution privileges
- **ERC1155Holder**: Safe storage of ERC1155 tokens

## Error Codes

- `#1000`: Below minimum amount
- `#1001`: Exceeds maximum amount
- `#1002`: Below minimum price
- `#1003`: Exceeds maximum price
- `#1004`: Invalid bid order
- `#1005`: Invalid ask order
- `#1006`: Insufficient bid order amount
- `#1007`: Insufficient ask order amount
- `#1008`: Input array length mismatch or incorrect ETH amount

## Deployment and Usage

### Deployment Requirements

- OperatorManager contract address

### Prerequisites for Usage

1. Deploy ERC1155 token contract
2. Set trade execution permissions in OperatorManager
3. Set token approval before creating sell orders

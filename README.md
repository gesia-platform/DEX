DEX CONTRACT

### 1. BID ORDER

```
PARAMETERS

token_contract_address (erc1155 token contract _address)
token_id
amount
price (must be in wei)
market_contract_address (erc20 token contract address)


FLOW : 
ERC20 token will deducted from BIDDER wallet_address


BACKEND should listen event : 
event BidEvent(address indexed user, address token_contract_address, uint256 token_id, uint256 amount, uint256 price, address market_contract_address, uint256 orderId);
Save to DB
Then add BID OrderBook

```

### 2. ASK ORDER

```
PARAMETERS

token_contract_address (erc1155 token contract _address)
token_id
amount
price (must be in wei)
market_contract_address (erc20 token contract address)

FLOW : 
ERC1155 token will deducted from ASKER wallet_address

BACKEND should listen event : 
event AskEvent(address indexed user, address token_contract_address, uint256 token_id, uint256 amount, uint256 price, address market_contract_address, uint256 orderId);
Save to DB
Then add ASK OrderBook
```

### 3. CANCEL ORDER

```
PARAMETERS

orderId

FLOW : 

if  orderId is BID : 
ERC20 token will transfer to BIDDER wallet_address
else orderId is ASK : 
ERC1155 token will transfer to ASKER wallet_address

BACKEND should listen event : 
event CancelEvent(address indexed user, address token_contract_address, uint256 token_id, uint256 amount, uint256 price, address market_contract_address, uint256 orderId);
Save to DB
Remove from OrderBook
```


### 4. EXECUTE ORDER

```
PARAMETERS

bidOrderId
askOrderId
orderAmount

FLOW : 
BACKEND match orders and find bidOrderId and askOrderId, then how many orderAmount is match to execute

BACKEND should listen event : 
event TradeExecuteEvent(address indexed seller, address indexed buyer, address token_contract_address, uint256 token_id,
        uint256 executedAmount, uint256 executedPrice, uint256 askOrderId, uint256 bidOrderId);
Save to DB
UPDATE OrderBook
```
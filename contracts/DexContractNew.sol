// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IDexProtocolNew.sol";
import "./interface/IOperator.sol";

contract DexContractNew is ERC1155Holder, ReentrancyGuard, IDexProtocolNew {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    event BidEvent(address indexed user, address token_contract_address, uint256 token_id, uint256 amount, uint256 price, uint256 orderId);
    event AskEvent(address indexed user, address token_contract_address, uint256 token_id, uint256 amount, uint256 price, uint256 orderId);
    event CancelEvent(address indexed user, address token_contract_address, uint256 token_id, uint256 amount, uint256 price, uint256 orderId);
    event CancelByOperatorEvent(address indexed operator, address token_contract_address, uint256 token_id, uint256 amount, uint256 price, uint256 orderId);
    event TradeExecuteEvent(address indexed seller, address indexed buyer, address token_contract_address, uint256 token_id,
        uint256 executedAmount, uint256 executedPrice, uint256 askOrderId, uint256 bidOrderId);
    event TradeExecuteInRefundEvent(address indexed asker, address indexed bidder, address tokenContractAddress, uint256 tokenId, 
        uint256 orderAmount, uint256 price, uint256 askOrderId, uint256 bidOrderId, uint256 refundedETH);

    Order[] public orders;

    Counters.Counter private _tokenIdTracker;

    uint256 public minAmount = 1;
    uint256 public minPrice = 1;
    uint256 public maxAmount = 1000;
    uint256 public maxPrice = 10000000000;
    address public operatorManager;

    modifier operatorsOnly() {
        require(IOperator(operatorManager).isOperator(msg.sender), "#operatorsOnly:");
        _;
    }

    constructor(address _operatorManager) {
        operatorManager = _operatorManager;
        _tokenIdTracker.increment();
        orders.push(Order(address(0), address(0), 0, 0, 0, false, false));
    }

    function bidOrder(address token_contract_address, uint256 token_id, uint256 amount, uint256 price)
    public
    payable
    override
    nonReentrant
    {
        require(amount >= minAmount, "#1000 : Must be higher than min amount");
        require(amount <= maxAmount, "#1001 : Must be less than max amount");
        require(price >= minPrice, "#1002 : Must be higher than min price");
        require(price <= maxPrice, "#1003 : Must be less than max price");

        uint256 orderPrice = amount.mul(price);
        require(msg.value == orderPrice, "#1008 : Incorrect ETH amount");

        uint256 orderId = _tokenIdTracker.current();
        orders.push(Order(msg.sender, token_contract_address, token_id, amount, price, true, true));
        emit BidEvent(msg.sender, token_contract_address, token_id, amount, price, orderId);
        _tokenIdTracker.increment();
    }

    function askOrder(address token_contract_address, uint256 token_id, uint256 amount, uint256 price)
    public
    override
    nonReentrant
    {
        require(amount >= minAmount, "#1000 : Must be higher than min amount");
        require(amount <= maxAmount, "#1001 : Must be less than max amount");
        require(price >= minPrice, "#1002 : Must be higher than min price");
        require(price <= maxPrice, "#1003 : Must be less than max price");

        IERC1155(token_contract_address).safeTransferFrom(msg.sender, address(this), token_id, amount, "");
        uint256 orderId = _tokenIdTracker.current();
        orders.push(Order(msg.sender, token_contract_address, token_id, amount, price, false, true));
        emit AskEvent(msg.sender, token_contract_address, token_id, amount, price, orderId);
        _tokenIdTracker.increment();
    }

    function cancelOrder(uint256[] memory orderIds)
    public
    override
    nonReentrant
    {
        for (uint256 i = 0; i < orderIds.length; i++) {
            Order storage order = orders[orderIds[i]];
            require(order.user == msg.sender || IOperator(operatorManager).isOperator(msg.sender), "#");
            require(order.isActive, "#1004 : Invalid bid order");
            if (order.isBuyOrder) {
                uint256 orderPrice = order.price.mul(order.amount);
                payable(order.user).transfer(orderPrice);  // Refund ETH
                emit CancelEvent(msg.sender, order.tokenContractAddress, order.tokenId, orderPrice, order.price, orderIds[i]);
            } else {
                IERC1155(order.tokenContractAddress).safeTransferFrom(address(this), order.user, order.tokenId, order.amount, "");
                emit CancelEvent(msg.sender, order.tokenContractAddress, order.tokenId, order.amount, order.price, orderIds[i]);
            }
            order.amount = 0;
            order.isActive = false;
        }
    }

    function executeOrder(
        uint256[] calldata bidOrderIds,
        uint256[] calldata askOrderIds,
        uint256[] calldata orderAmounts
    ) public override operatorsOnly nonReentrant {
        require(
            bidOrderIds.length == askOrderIds.length &&
            askOrderIds.length == orderAmounts.length,
            "#1008 : Input arrays must have the same length"
        );

        for (uint256 i = 0; i < bidOrderIds.length; i++) {
            uint256 bidOrderId = bidOrderIds[i];
            uint256 askOrderId = askOrderIds[i];
            uint256 orderAmount = orderAmounts[i];

            require(orders[bidOrderId].isBuyOrder && orders[bidOrderId].isActive, "#1004 : Invalid bid order");
            require(!orders[askOrderId].isBuyOrder && orders[askOrderId].isActive, "#1005 : Invalid ask order");

            Order storage bidOrder = orders[bidOrderId];
            Order storage askOrder = orders[askOrderId];

            require(bidOrder.amount >= orderAmount, "#1006 : Not Enough Bid Order Amount");
            require(askOrder.amount >= orderAmount, "#1007 : Not Enough Ask Order Amount");

            uint256 orderPrice = askOrder.price.mul(orderAmount);

            // Transfer ETH from contract to asker's wallet
            payable(askOrder.user).transfer(orderPrice);

            // Execute ERC1155 transfer for each bid-ask pair
            IERC1155(askOrder.tokenContractAddress).safeTransferFrom(
                address(this),
                bidOrder.user,
                askOrder.tokenId,
                orderAmount,
                ""
            );

            // Update order amounts
            bidOrder.amount = bidOrder.amount.sub(orderAmount);
            askOrder.amount = askOrder.amount.sub(orderAmount);

            // Set orders to inactive if amounts reach zero
            bidOrder.isActive = bidOrder.amount > 0;
            askOrder.isActive = askOrder.amount > 0;

            // Emit trade execution event for each order
            emit TradeExecuteEvent(
                askOrder.user,
                bidOrder.user,
                bidOrder.tokenContractAddress,
                bidOrder.tokenId,
                orderAmount,
                askOrder.price,
                askOrderId,
                bidOrderId
            );
        }
    }

    function executeOrderWithRefund(
        uint256[] calldata bidOrderIds,
        uint256[] calldata askOrderIds,
        uint256[] calldata orderAmounts
    ) public operatorsOnly nonReentrant {
        require(
        bidOrderIds.length == askOrderIds.length &&
        askOrderIds.length == orderAmounts.length,
        "#1008 : Input arrays must have the same length"
        );

        for (uint256 i = 0; i < bidOrderIds.length; i++) {
            uint256 bidOrderId = bidOrderIds[i];
            uint256 askOrderId = askOrderIds[i];
            uint256 orderAmount = orderAmounts[i];

            require(orders[bidOrderId].isBuyOrder && orders[bidOrderId].isActive, "#1004 : Invalid bid order");
            require(!orders[askOrderId].isBuyOrder && orders[askOrderId].isActive, "#1005 : Invalid ask order");

            Order storage bidOrder = orders[bidOrderId];
            Order storage askOrder = orders[askOrderId];

            require(bidOrder.amount >= orderAmount, "#1006 : Not Enough Bid Order Amount");
            require(askOrder.amount >= orderAmount, "#1007 : Not Enough Ask Order Amount");

            uint256 orderTotal = askOrder.price.mul(orderAmount);

            // 계약에서 asker's wallet로 ETH 전송
            payable(askOrder.user).transfer(orderTotal);

            // ERC1155 토큰 전송
            IERC1155(askOrder.tokenContractAddress).safeTransferFrom(
                address(this),
                bidOrder.user,
                askOrder.tokenId,
                orderAmount,
                ""
            );

            bidOrder.isActive = false;
            askOrder.isActive = false;

            // 초과 금액 계산 (입찰자가 지불한 금액에서 판매 금액을 뺀 값)
            uint256 bidTotal = bidOrder.price.mul(bidOrder.amount);
            uint256 excessETH = bidTotal - orderTotal;  // 초과 금액

            bidOrder.amount = bidOrder.amount.sub(bidOrder.amount);
            askOrder.amount = askOrder.amount.sub(orderAmount);

            // 초과 ETH 환불
            if (excessETH > 0) {
                payable(bidOrder.user).transfer(excessETH);  // 환불 처리
            }

            emit TradeExecuteInRefundEvent(
                askOrder.user,
                bidOrder.user,
                bidOrder.tokenContractAddress,
                bidOrder.tokenId,
                orderAmount,
                askOrder.price,
                askOrderId,
                bidOrderId,
                excessETH
            );
        }
    }

    function detailOrder(uint256 orderId)
    external
    override
    view
    returns (Order memory)
    {
        return orders[orderId];
    }

    receive() external payable {}
}

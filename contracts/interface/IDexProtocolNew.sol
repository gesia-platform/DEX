pragma solidity ^0.8.0;

// IDexProtocol: Interface for a Decentralized Exchange (DEX) Protocol
// This interface defines the essential functions for creating and managing orders
// in a DEX environment, including functionalities for placing, canceling, and executing orders.
interface IDexProtocolNew {

    // Order: Struct representing an order in the DEX
    // Contains details about the order such as the user who placed it, the token being traded,
    // the amount and price of the token, and its active status.
    struct Order {
        address user;                   // Address of the user who created the order
        address tokenContractAddress;   // Contract address of the token being traded (ERC1155 contract)
        uint256 tokenId;                // ID of the token (ERC-1155 tokens)
        uint256 amount;                 // Amount of the token to be traded
        uint256 price;                  // Price per unit of the token
        bool isBuyOrder;                // True if it's a buy order, false if it's a sell order
        bool isActive;                  // True if the order is active, false if fulfilled or cancelled
    }

    // bidOrder: Function to create a buy order on the DEX
    // Parameters are the details of the order including the token, amount, price, and market contract.
    function bidOrder(
        address tokenContractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external payable;

    // askOrder: Function to create a sell order on the DEX
    // Parameters are the details of the order including the token, amount, price, and market contract.
    function askOrder(
        address tokenContractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external;

    // cancelOrder: Function to cancel an existing order on the DEX
    // Parameter is the unique identifier of the order to be cancelled.
    function cancelOrder(uint256[] memory orderIds) external;

    // executeOrder: Function to execute a trade between a buy order and a sell order
    // Parameters include the IDs of the buy and sell orders and the amount to be traded.
    function executeOrder(
        uint256[] calldata bidOrderIds,
        uint256[] calldata askOrderIds,
        uint256[] calldata orderAmounts
    ) external;

    // detailOrder: Function to retrieve details of a specific order
    // Parameter is the unique identifier of the order.
    // Returns an Order struct containing the details of the specified order.
    function detailOrder(uint256 orderId) external view returns (Order memory);
}

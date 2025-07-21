// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IOperator.sol";

contract OperatorManager is Ownable, IOperator {
    mapping(address => bool) public operatorMap;

    event AddOperator(address account);
    event RemoveOperator(address account);

    constructor() {
        operatorMap[msg.sender] = true;
    }

    function addOperator(address _account) external onlyOwner {
        operatorMap[_account] = true;
        emit AddOperator(_account);
    }

    function removeOperator(address _account) external onlyOwner {
        operatorMap[_account] = false;
        emit RemoveOperator(_account);
    }

    function isOperator(
        address _account
    ) external view override returns (bool) {
        return operatorMap[_account];
    }
}

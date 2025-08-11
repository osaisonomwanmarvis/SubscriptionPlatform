// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockOracle {
    int256 private price;

    constructor(int256 _initialPrice) {
        price = _initialPrice;
    }

    function setPrice(int256 _price) external {
        price = _price;
    }

    function latestAnswer() external view returns (int256) {
        return price;
    }
}
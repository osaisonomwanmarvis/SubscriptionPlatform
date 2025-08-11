// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library PlatformMath {
    function applyPlatformFee(uint256 amount, uint256 feePercent) internal pure returns (uint256) {
        return (amount * feePercent) / 10000; // feePercent in basis points
    }
}
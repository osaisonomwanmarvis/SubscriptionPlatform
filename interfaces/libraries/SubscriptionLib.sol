// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SubscriptionLib {
    function calculateNewExpiry(
        uint256 currentExpiry,
        uint256 duration
    ) internal view returns (uint256) {
        return block.timestamp > currentExpiry
            ? block.timestamp + duration
            : currentExpiry + duration;
    }

    function isExpired(uint256 expiry) internal view returns (bool) {
        return block.timestamp > expiry;
    }
}
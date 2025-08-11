// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICreatorTiers {
    struct SubscriptionPlan {
        uint256 fee;
        uint256 tokenFee;
        uint256 duration;
        string metadata;
        string benefits;
    }

    event PlanUpdated(
        address indexed creator,
        uint256 tierIndex,
        uint256 fee,
        uint256 tokenFee,
        uint256 duration,
        string metadata,
        string benefits
    );

    function updateCreatorPlan(
        uint256 tierIndex,
        uint256 fee,
        uint256 tokenFee,
        uint256 duration,
        string calldata metadata,
        string calldata benefits
    ) external;
}

3️⃣ libr
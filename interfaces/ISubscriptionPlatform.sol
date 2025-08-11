// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISubscriptionPlatform {
    struct SubscriptionPlan {
        uint256 fee;
        uint256 tokenFee;
        uint256 duration;
        string metadata;
        string benefits;
    }

    struct SubscriptionRecord {
        address user;
        uint256 startTime;
        uint256 endTime;
        uint256 amountPaid;
        string paymentMethod;
    }

    event Subscribed(address indexed user, address indexed creator, uint256 expiry);
    event SubscribedWithToken(address indexed user, address indexed creator, uint256 expiry);

    function subscribe(address creator, uint256 tierIndex) external payable;
    function subscribeWithToken(address creator, uint256 tierIndex, address token, uint256 amount) external;
    function enableAutoRenewal(address creator) external;
    function disableAutoRenewal(address creator) external;
    function suspendSubscription(address creator) external;
    function reactivateSubscription(address creator) external;
}
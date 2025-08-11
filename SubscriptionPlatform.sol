// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interfaces
import "./interfaces/ISubscriptionPlatform.sol";
import "./interfaces/ICreatorTiers.sol";

// Libraries
import "./libraries/SubscriptionLib.sol";
import "./libraries/PlatformMath.sol";

contract SubscriptionPlatform is 
    ReentrancyGuard, 
    ISubscriptionPlatform, 
    ICreatorTiers 
{
    using SubscriptionLib for uint256;
    using PlatformMath for uint256;

    address public owner;
    uint256 public platformFee = 0.01 ether; // Fixed ETH fee
    uint256 public platformTokenFee = 10 * 10**18; // Fixed token fee
    uint256 public platformDuration = 30 days;
    uint256 public totalSubscribers;
    uint256 public gracePeriod = 7 days;
    bool public paused = false;

    IERC20 public defaultPaymentToken;

    // Mappings
    mapping(address => mapping(address => uint256)) public creatorSubscriptions; // creator -> user -> expiry
    mapping(address => bool) public creators;
    mapping(address => SubscriptionPlan[]) public creatorTiers;
    mapping(address => CreatorAnalytics) public creatorAnalytics;
    mapping(address => SubscriptionRecord[]) public subscriptionHistory;
    mapping(address => mapping(address => bool)) public autoRenewal; 
    mapping(address => bool) public whitelistedTokens;
    mapping(address => mapping(address => uint256)) public suspendedSubscriptions; 

    struct CreatorAnalytics {
        uint256 totalEarningsETH;
        uint256 totalEarningsTokens;
        uint256 activeSubscribers;
        uint256 totalSubscribers;
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyCreator() {
        require(creators[msg.sender], "Not a creator");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(address _defaultTokenAddress) {
        owner = msg.sender;
        defaultPaymentToken = IERC20(_defaultTokenAddress);
        creators[msg.sender] = true;
    }

    // -------------------------
    // Subscription Functions
    // -------------------------
    function subscribe(address creator, uint256 tierIndex) 
        external 
        payable 
        override 
        notPaused 
    {
        require(creators[creator], "Invalid creator");
        require(tierIndex < creatorTiers[creator].length, "Invalid tier index");

        SubscriptionPlan memory plan = creatorTiers[creator][tierIndex];
        require(msg.value >= plan.fee, "Incorrect ETH payment");

        _processSubscription(creator, plan.duration, msg.value, 0, "ETH");

        emit Subscribed(msg.sender, creator, creatorSubscriptions[creator][msg.sender]);
    }

    function subscribeWithToken(
        address creator,
        uint256 tierIndex,
        address token,
        uint256 amount
    ) external override notPaused {
        require(creators[creator], "Invalid creator");
        require(tierIndex < creatorTiers[creator].length, "Invalid tier index");
        require(whitelistedTokens[token], "Token not supported");

        SubscriptionPlan memory plan = creatorTiers[creator][tierIndex];
        require(amount >= plan.tokenFee, "Insufficient token amount");

        IERC20 paymentToken = IERC20(token);
        require(paymentToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        _processSubscription(creator, plan.duration, 0, amount, "Token");

        emit SubscribedWithToken(msg.sender, creator, creatorSubscriptions[creator][msg.sender]);
    }

    function validateSubscriptionInputs(address creator, uint256 tierIndex) internal view {
        require(creator != address(0), "SUBSCRIPTION_PLATFORM: Creator address cannot be zero");
        require(creators[creator], "SUBSCRIPTION_PLATFORM: Creator not registered");
        require(tierIndex < creatorTiers[creator].length, "SUBSCRIPTION_PLATFORM: Invalid tier index");
        require(creatorTiers[creator][tierIndex].duration > 0, "SUBSCRIPTION_PLATFORM: Invalid plan duration");
    }

    function enableAutoRenewal(address creator) external override {
        autoRenewal[creator][msg.sender] = true;
        emit AutoRenewalEnabled(creator, msg.sender);
    }

    function disableAutoRenewal(address creator) external override {
        autoRenewal[creator][msg.sender] = false;
        emit AutoRenewalDisabled(creator, msg.sender);
    }

    function suspendSubscription(address creator) external override {
        require(creatorSubscriptions[creator][msg.sender] > block.timestamp, "No active subscription");
        suspendedSubscriptions[creator][msg.sender] = creatorSubscriptions[creator][msg.sender];
        creatorSubscriptions[creator][msg.sender] = 0;
        emit SubscriptionSuspended(msg.sender, creator, suspendedSubscriptions[creator][msg.sender]);
    }

    function reactivateSubscription(address creator) external override {
        require(suspendedSubscriptions[creator][msg.sender] > 0, "No suspended subscription");
        creatorSubscriptions[creator][msg.sender] = suspendedSubscriptions[creator][msg.sender];
        suspendedSubscriptions[creator][msg.sender] = 0;
        emit SubscriptionReactivated(msg.sender, creator, creatorSubscriptions[creator][msg.sender]);
    }

    function _processSubscription(
        address creator,
        uint256 duration,
        uint256 ethPaid,
        uint256 tokensPaid,
        string memory paymentMethod
    ) internal {
        if (block.timestamp >= creatorSubscriptions[creator][msg.sender]) {
            creatorAnalytics[creator].activeSubscribers += 1;
            creatorAnalytics[creator].totalSubscribers += 1;
        }

        uint256 newExpiry = SubscriptionLib.calculateNewExpiry(
            creatorSubscriptions[creator][msg.sender],
            duration
        );

        creatorSubscriptions[creator][msg.sender] = newExpiry;

        if (ethPaid > 0) {
            creatorAnalytics[creator].totalEarningsETH += ethPaid;
        }
        if (tokensPaid > 0) {
            creatorAnalytics[creator].totalEarningsTokens += tokensPaid;
        }

        subscriptionHistory[msg.sender].push(
            SubscriptionRecord({
                user: msg.sender,
                startTime: block.timestamp,
                endTime: newExpiry,
                amountPaid: ethPaid > 0 ? ethPaid : tokensPaid,
                paymentMethod: paymentMethod
            })
        );
    }

    // -------------------------
    // Creator Management
    // -------------------------
    function addCreator(address creator) external override onlyOwner {
        creators[creator] = true;
        emit CreatorAdded(creator);
    }

    function removeCreator(address creator) external override onlyOwner {
        creators[creator] = false;
        delete creatorSubscriptions[creator];
        delete creatorTiers[creator];
        emit CreatorRemoved(creator);
    }

    function updateCreatorPlan(
        uint256 tierIndex,
        uint256 fee,
        uint256 tokenFee,
        uint256 duration,
        string calldata metadata,
        string calldata benefits
    ) external override onlyCreator {
        if (tierIndex < creatorTiers[msg.sender].length) {
            creatorTiers[msg.sender][tierIndex] = SubscriptionPlan(fee, tokenFee, duration, metadata, benefits);
        } else {
            creatorTiers[msg.sender].push(SubscriptionPlan(fee, tokenFee, duration, metadata, benefits));
        }
        emit PlanUpdated(msg.sender, tierIndex, fee, tokenFee, duration, metadata, benefits);
    }

    // -------------------------
    // Platform Controls
    // -------------------------
    function addWhitelistedToken(address token) external onlyOwner {
        whitelistedTokens[token] = true;
    }

    function removeWhitelistedToken(address token) external onlyOwner {
        delete whitelistedTokens[token];
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }
}
#  Function Reference Guide

Complete documentation for all functions in the SubscriptionPlatform contract.

##  Table of Contents

1. [Subscription Functions](#-subscription-functions)
2. [Creator Management Functions](#-creator-management-functions)
3. [Administrative Functions](#-administrative-functions)
4. [View Functions](#-view-functions)
5. [Modifiers](#-modifiers)
6. [Error Conditions](#-error-conditions)

---

##  Subscription Functions

### `subscribe(address creator, uint256 tierIndex)`

Subscribe to a creator's tier using ETH payment.

**Function Signature:**
```solidity
function subscribe(address creator, uint256 tierIndex) external payable notPaused
```

**Parameters:**
- `creator` (address): The address of the content creator
- `tierIndex` (uint256): The index of the subscription tier (0-based)

**Requirements:**
- Contract must not be paused
- Creator must be registered (`creators[creator] == true`)
- `tierIndex` must be valid (`< creatorTiers[creator].length`)
- `msg.value` must be >= the tier's ETH fee
- Sufficient ETH sent with transaction

**Behavior:**
- Extends existing subscription or creates new one
- Updates creator analytics (earnings, subscriber count)
- Records transaction in subscription history
- Emits `Subscribed` event

**Events Emitted:**
```solidity
event Subscribed(address indexed user, address indexed creator, uint256 expiry);
```

**Gas Estimate:** ~120,000

**Example Usage:**
```javascript
// Subscribe to creator's tier 0 with 0.1 ETH
const tx = await contract.subscribe(creatorAddress, 0, {
  value: ethers.utils.parseEther("0.1")
});
```

---

### `subscribeWithToken(address creator, uint256 tierIndex, address token, uint256 amount)`

Subscribe to a creator's tier using ERC20 token payment.

**Function Signature:**
```solidity
function subscribeWithToken(address creator, uint256 tierIndex, address token, uint256 amount) external notPaused
```

**Parameters:**
- `creator` (address): The address of the content creator
- `tierIndex` (uint256): The index of the subscription tier
- `token` (address): The ERC20 token contract address
- `amount` (uint256): The amount of tokens to pay

**Requirements:**
- Contract must not be paused
- Creator must be registered
- `tierIndex` must be valid
- Token must be whitelisted (`whitelistedTokens[token] == true`)
- `amount` must be >= the tier's token fee
- User must have approved the contract to spend tokens
- Token transfer must succeed

**Behavior:**
- Transfers tokens from user to contract
- Extends existing subscription or creates new one
- Updates creator analytics
- Records transaction history
- Emits `SubscribedWithToken` event

**Events Emitted:**
```solidity
event SubscribedWithToken(address indexed user, address indexed creator, uint256 expiry);
```

**Gas Estimate:** ~140,000

**Example Usage:**
```javascript
// First approve token spending
await token.approve(contractAddress, tokenAmount);

// Then subscribe with tokens
await contract.subscribeWithToken(creatorAddress, 0, tokenAddress, tokenAmount);
```

---

### `enableAutoRenewal(address creator)`

Enable automatic renewal for a creator's subscription.

**Function Signature:**
```solidity
function enableAutoRenewal(address creator) external
```

**Parameters:**
- `creator` (address): The creator whose subscription to auto-renew

**Requirements:**
- No specific requirements (any address can call)

**Behavior:**
- Sets `autoRenewal[creator][msg.sender] = true`
- Emits `AutoRenewalEnabled` event

**Events Emitted:**
```solidity
event AutoRenewalEnabled(address indexed creator, address indexed user);
```

**Gas Estimate:** ~45,000

**Note:** Auto-renewal logic must be implemented externally (not in current contract).

---

### `disableAutoRenewal(address creator)`

Disable automatic renewal for a creator's subscription.

**Function Signature:**
```solidity
function disableAutoRenewal(address creator) external
```

**Parameters:**
- `creator` (address): The creator whose subscription auto-renewal to disable

**Requirements:**
- No specific requirements

**Behavior:**
- Sets `autoRenewal[creator][msg.sender] = false`
- Emits `AutoRenewalDisabled` event

**Events Emitted:**
```solidity
event AutoRenewalDisabled(address indexed creator, address indexed user);
```

**Gas Estimate:** ~30,000

---

### `suspendSubscription(address creator)`

Temporarily suspend an active subscription.

**Function Signature:**
```solidity
function suspendSubscription(address creator) external
```

**Parameters:**
- `creator` (address): The creator whose subscription to suspend

**Requirements:**
- User must have an active subscription (`creatorSubscriptions[creator][msg.sender] > block.timestamp`)

**Behavior:**
- Saves current expiry time to `suspendedSubscriptions` mapping
- Clears active subscription (`creatorSubscriptions[creator][msg.sender] = 0`)
- Emits `SubscriptionSuspended` event

**Events Emitted:**
```solidity
event SubscriptionSuspended(address indexed user, address indexed creator, uint256 suspensionTime);
```

**Gas Estimate:** ~45,000

**Use Cases:**
- Temporary content access pause
- Account management by user
- Dispute resolution

---

### `reactivateSubscription(address creator)`

Reactivate a previously suspended subscription.

**Function Signature:**
```solidity
function reactivateSubscription(address creator) external
```

**Parameters:**
- `creator` (address): The creator whose subscription to reactivate

**Requirements:**
- User must have a suspended subscription (`suspendedSubscriptions[creator][msg.sender] > 0`)

**Behavior:**
- Restores subscription with original expiry time
- Clears suspended subscription record
- Emits `SubscriptionReactivated` event

**Events Emitted:**
```solidity
event SubscriptionReactivated(address indexed user, address indexed creator, uint256 expiry);
```

**Gas Estimate:** ~40,000

**Important:** Reactivated subscriptions use the original expiry time, not extended from current time.

---

##  Creator Management Functions

### `updateCreatorPlan(uint256 tierIndex, uint256 fee, uint256 tokenFee, uint256 duration, string memory metadata, string memory benefits)`

Create a new subscription tier or update an existing one.

**Function Signature:**
```solidity
function updateCreatorPlan(uint256 tierIndex, uint256 fee, uint256 tokenFee, uint256 duration, string memory metadata, string memory benefits) external onlyCreator
```

**Parameters:**
- `tierIndex` (uint256): Index of tier to update, or next available index for new tier
- `fee` (uint256): ETH price for this tier (in wei)
- `tokenFee` (uint256): ERC20 token price for this tier
- `duration` (uint256): Subscription duration in seconds
- `metadata` (string): Detailed plan description
- `benefits` (string): Key benefits of the plan

**Requirements:**
- Caller must be a registered creator (`onlyCreator` modifier)

**Behavior:**
- If `tierIndex < creatorTiers[creator].length`: Updates existing tier
- If `tierIndex >= creatorTiers[creator].length`: Creates new tier
- Emits `PlanUpdated` event

**Events Emitted:**
```solidity
event PlanUpdated(address indexed creator, uint256 tierIndex, uint256 fee, uint256 tokenFee, uint256 duration, string metadata, string benefits);
```

**Gas Estimate:** ~80,000

**Example Usage:**
```javascript
await contract.updateCreatorPlan(
  0,                                    // tierIndex
  ethers.utils.parseEther("0.05"),     // 0.05 ETH
  ethers.utils.parseUnits("50", 18),   // 50 tokens
  2592000,                             // 30 days in seconds
  "Premium Content Access",             // metadata
  "Ad-free, HD content, early access"  // benefits
);
```

---

##  Administrative Functions

### `addCreator(address creator)`

Add a new creator to the platform.

**Function Signature:**
```solidity
function addCreator(address creator) external onlyOwner
```

**Parameters:**
- `creator` (address): Address to grant creator privileges

**Requirements:**
- Caller must be contract owner (`onlyOwner` modifier)

**Behavior:**
- Sets `creators[creator] = true`
- Emits `CreatorAdded` event

**Events Emitted:**
```solidity
event CreatorAdded(address indexed creator);
```

**Gas Estimate:** ~45,000

---

### `removeCreator(address creator)`

Remove a creator from the platform and delete their data.

**Function Signature:**
```solidity
function removeCreator(address creator) external onlyOwner
```

**Parameters:**
- `creator` (address): Creator address to remove

**Requirements:**
- Caller must be contract owner

**Behavior:**
- Sets `creators[creator] = false`
- Deletes all creator subscriptions (`delete creatorSubscriptions[creator]`)
- Deletes all creator tiers (`delete creatorTiers[creator]`)
- Emits `CreatorRemoved` event

**Events Emitted:**
```solidity
event CreatorRemoved(address indexed creator);
```

**Gas Estimate:** Variable (depends on amount of data to delete)

** Warning:** This permanently deletes all creator data and active subscriptions.

---

### `addWhitelistedToken(address token)`

Add an ERC20 token to the whitelist for payments.

**Function Signature:**
```solidity
function addWhitelistedToken(address token) external onlyOwner
```

**Parameters:**
- `token` (address): ERC20 token contract address

**Requirements:**
- Caller must be contract owner

**Behavior:**
- Sets `whitelistedTokens[token] = true`

**Gas Estimate:** ~45,000

---

### `removeWhitelistedToken(address token)`

Remove an ERC20 token from the payment whitelist.

**Function Signature:**
```solidity
function removeWhitelistedToken(address token) external onlyOwner
```

**Parameters:**
- `token` (address): ERC20 token contract address to remove

**Requirements:**
- Caller must be contract owner

**Behavior:**
- Deletes `whitelistedTokens[token]` (sets to false)

**Gas Estimate:** ~30,000

---

### `pause()`

Emergency pause the contract, disabling all subscription functions.

**Function Signature:**
```solidity
function pause() external onlyOwner
```

**Requirements:**
- Caller must be contract owner

**Behavior:**
- Sets `paused = true`
- Emits `Paused` event

**Events Emitted:**
```solidity
event Paused();
```

**Gas Estimate:** ~30,000

---

### `unpause()`

Unpause the contract, re-enabling subscription functions.

**Function Signature:**
```solidity
function unpause() external onlyOwner
```

**Requirements:**
- Caller must be contract owner

**Behavior:**
- Sets `paused = false`
- Emits `Unpaused` event

**Events Emitted:**
```solidity
event Unpaused();
```

**Gas Estimate:** ~30,000

---

##  View Functions

The following public state variables can be read directly:

### Platform Configuration
```solidity
address public owner;                    // Contract owner
uint256 public platformFee;             // Default ETH fee (0.01 ether)
uint256 public platformTokenFee;        // Default token fee (10 * 10**18)
uint256 public platformDuration;        // Default duration (30 days)
uint256 public totalSubscribers;        // Total platform subscribers
uint256 public gracePeriod;             // Grace period (7 days)
bool public paused;                     // Contract pause status
IERC20 public defaultPaymentToken;      // Default payment token
```

### Mappings (Public Getters)
```solidity
// Check subscription expiry
creatorSubscriptions[creator][user] returns uint256 expiry

// Check if address is creator
creators[creator] returns bool isCreator

// Get creator's subscription tiers
creatorTiers[creator][tierIndex] returns SubscriptionPlan

// Get creator analytics
creatorAnalytics[creator] returns CreatorAnalytics

// Get user's subscription history
subscriptionHistory[user][index] returns SubscriptionRecord

// Check auto-renewal status
autoRenewal[creator][user] returns bool enabled

// Check if token is whitelisted
whitelistedTokens[token] returns bool whitelisted

// Check suspended subscriptions
suspendedSubscriptions[creator][user] returns uint256 suspensionTime
```

---

##  Modifiers

### `onlyOwner()`
```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Not the owner");
    _;
}
```
Restricts function access to contract owner only.

### `onlyCreator()`
```solidity
modifier onlyCreator() {
    require(creators[msg.sender], "Not a creator");
    _;
}
```
Restricts function access to registered creators only.

### `notPaused()`
```solidity
modifier notPaused() {
    require(!paused, "Contract is paused");
    _;
}
```
Prevents function execution when contract is paused.

---

##  Error Conditions

### Common Errors

| Error Message | Cause | Functions Affected |
|---------------|-------|-------------------|
| `"Not the owner"` | Caller is not contract owner | All `onlyOwner` functions |
| `"Not a creator"` | Caller is not registered creator | `updateCreatorPlan` |
| `"Contract is paused"` | Contract is in paused state | All `notPaused` functions |
| `"Invalid creator"` | Creator address not registered | `subscribe`, `subscribeWithToken` |
| `"Invalid tier index"` | tierIndex >= available tiers | `subscribe`, `subscribeWithToken` |
| `"Incorrect ETH payment"` | msg.value < required fee | `subscribe` |
| `"Token not supported"` | Token not in whitelist | `subscribeWithToken` |
| `"Insufficient token amount"` | amount < required token fee | `subscribeWithToken` |
| `"Token transfer failed"` | ERC20 transfer unsuccessful | `subscribeWithToken` |
| `"No active subscription"` | User has no active subscription | `suspendSubscription` |
| `"No suspended subscription"` | User has no suspended subscription | `reactivateSubscription` |

### Debugging Tips

1. **Check subscription status**: Use `creatorSubscriptions[creator][user]` to verify expiry times
2. **Verify permissions**: Ensure caller has required role (owner/creator)
3. **Confirm token allowance**: For token payments, check ERC20 approval
4. **Validate tier index**: Ensure tier exists in `creatorTiers[creator]`
5. **Check pause status**: Verify contract is not paused

---

##  Function Flow Examples

### Complete Subscription Flow
```javascript
// 1. Creator creates subscription tier
await contract.connect(creator).updateCreatorPlan(0, fee, tokenFee, duration, metadata, benefits);

// 2. User subscribes with ETH
await contract.connect(user).subscribe(creatorAddress, 0, {value: fee});

// 3. Check subscription status
const expiry = await contract.creatorSubscriptions(creatorAddress, userAddress);
const isActive = expiry > Date.now() / 1000;

// 4. Enable auto-renewal (optional)
await contract.connect(user).enableAutoRenewal(creatorAddress);

// 5. Suspend subscription (optional)
await contract.connect(user).suspendSubscription(creatorAddress);

// 6. Reactivate subscription
await contract.connect(user).reactivateSubscription(creatorAddress);
```

This completes the comprehensive function reference guide for your SubscriptionPlatform contract!
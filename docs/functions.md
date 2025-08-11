# 📚 Function Reference

## Subscription Functions

### `subscribe(address creator, uint256 tierIndex)`
Subscribe to a creator using ETH payment.

**Parameters:**
- `creator`: Address of the creator to subscribe to
- `tierIndex`: Index of the subscription tier (0-based)

**Requirements:**
- Contract not paused
- Valid creator address
- Valid tier index
- Sufficient ETH sent (>= tier fee)

**Events:** `Subscribed(user, creator, expiry)`

**Gas Cost:** ~85,000

### `subscribeWithToken(address creator, uint256 tierIndex, address token, uint256 amount)`
Subscribe using ERC20 tokens.

**Parameters:**
- `creator`: Creator address
- `tierIndex`: Subscription tier index  
- `token`: ERC20 token address
- `amount`: Token amount to pay

**Requirements:**
- Token must be whitelisted
- Sufficient token allowance
- Amount >= tier token fee

**Events:** `SubscribedWithToken(user, creator, expiry)`

**Gas Cost:** ~120,000

[Continue for all functions...]
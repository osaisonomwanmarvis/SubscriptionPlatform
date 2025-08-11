# Subscription Platform Integration Guide

## Quick Start
1. Deploy contract with default payment token
2. Register as creator: `addCreator(address)`  
3. Create subscription tiers: `updateCreatorPlan(...)`
4. Users can subscribe: `subscribe()` or `subscribeWithToken()`

## Key Functions for Frontend Integration

### For Creators
- `updateCreatorPlan()` - Create/update subscription tiers
- `creatorAnalytics[address]` - View earnings and subscriber data

### For Users  
- `subscribe()` - Pay with ETH
- `subscribeWithToken()` - Pay with ERC20 tokens
- `enableAutoRenewal()` - Set up automatic renewals
- `subscriptionHistory[address]` - View payment history

### For Platforms
- `creatorSubscriptions[creator][user]` - Check subscription status
- `getBalance()` - Check platform revenue
- `withdraw()` - Withdraw platform fees

## Events to Listen For
- `Subscribed` - New ETH subscription
- `SubscribedWithToken` - New token subscription  
- `PlanUpdated` - Creator modified their tiers
# 🔧 Integration Guide

## Frontend Integration

### 1. Contract Setup
\```typescript
import { ethers } from 'ethers';
import SubscriptionPlatformABI from './abis/SubscriptionPlatform.json';

const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();

const contract = new ethers.Contract(
  "0x1234567890123456789012345678901234567890", // Contract address
  SubscriptionPlatformABI,
  signer
);
\```

### 2. Check Subscription Status
\```typescript
const checkSubscription = async (creator: string, user: string) => {
  const expiry = await contract.creatorSubscriptions(creator, user);
  const currentTime = Math.floor(Date.now() / 1000);
  return expiry.toNumber() > currentTime;
};
\```

### 3. Subscribe with ETH
\```typescript
const subscribeWithETH = async (
  creator: string, 
  tierIndex: number, 
  ethAmount: string
) => {
  try {
    const tx = await contract.subscribe(creator, tierIndex, {
      value: ethers.utils.parseEther(ethAmount),
      gasLimit: 100000 // Recommended gas limit
    });
    
    const receipt = await tx.wait();
    console.log('Subscription successful:', receipt.transactionHash);
    return receipt;
  } catch (error) {
    console.error('Subscription failed:', error);
    throw error;
  }
};
\```

### 4. Subscribe with Tokens
\```typescript
const subscribeWithTokens = async (
  creator: string,
  tierIndex: number,
  tokenAddress: string,
  amount: string
) => {
  // First, approve token spending
  const tokenContract = new ethers.Contract(
    tokenAddress,
    ERC20_ABI,
    signer
  );
  
  const approveTx = await tokenContract.approve(
    contract.address,
    ethers.utils.parseEther(amount)
  );
  await approveTx.wait();
  
  // Then subscribe
  const tx = await contract.subscribeWithToken(
    creator,
    tierIndex,
    tokenAddress,
    ethers.utils.parseEther(amount)
  );
  
  return await tx.wait();
};
\```

### 5. Event Listening
\```typescript
// Listen for subscription events
contract.on("Subscribed", (user, creator, expiry, event) => {
  console.log(\`New subscription: \${user} -> \${creator}\`);
  console.log(\`Expires: \${new Date(expiry * 1000)}\`);
});

contract.on("SubscribedWithToken", (user, creator, expiry, event) => {
  console.log(\`Token subscription: \${user} -> \${creator}\`);
});
\```

### 6. Error Handling
\```typescript
const handleContractError = (error: any) => {
  if (error.code === 'UNPREDICTABLE_GAS_LIMIT') {
    return 'Transaction may fail. Check parameters.';
  }
  
  if (error.reason === 'Invalid creator') {
    return 'Creator not found or not registered.';
  }
  
  if (error.reason === 'Incorrect ETH payment') {
    return 'Insufficient ETH sent for subscription.';
  }
  
  return 'Transaction failed. Please try again.';
};
\```

## Backend Integration

### Node.js Setup
\```javascript
const { ethers } = require('ethers');

const provider = new ethers.providers.JsonRpcProvider(
  'https://mainnet.infura.io/v3/YOUR-PROJECT-ID'
);

const contract = new ethers.Contract(
  CONTRACT_ADDRESS,
  ABI,
  provider
);

// Monitor subscription events
const monitorSubscriptions = () => {
  contract.on('Subscribed', async (user, creator, expiry) => {
    // Update database
    await updateUserSubscription(user, creator, expiry);
    
    // Send notification
    await sendSubscriptionConfirmation(user, creator);
  });
};
\```

### GraphQL Integration
\```typescript
// Schema for subscription data
const typeDefs = gql\`
  type Subscription {
    id: ID!
    user: String!
    creator: String!
    expiry: String!
    tier: Int!
    active: Boolean!
  }
  
  type Query {
    userSubscriptions(user: String!): [Subscription!]!
    creatorSubscriptions(creator: String!): [Subscription!]!
  }
\`;

// Resolver
const resolvers = {
  Query: {
    userSubscriptions: async (_, { user }) => {
      // Query blockchain for user's subscriptions
      const subscriptions = [];
      // Implementation details...
      return subscriptions;
    }
  }
};
\```

[Continue with more integration examples...]
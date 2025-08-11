const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying with account:", deployer.address);
    
    // Deploy with USDC as default token (mainnet: 0xA0b86a33E6417c7C8b44d91bB5C45E5C5eA7C8b24)
    const defaultToken = "0xA0b86a33E6417c7C8b44d91bB5C45E5C5eA7C8b24";
    
    const SubscriptionPlatform = await ethers.getContractFactory("SubscriptionPlatform");
    const platform = await SubscriptionPlatform.deploy(defaultToken);
    
    await platform.deployed();
    console.log("SubscriptionPlatform deployed to:", platform.address);
    
    // Setup initial configuration
    await platform.addWhitelistedToken(defaultToken); // Add USDC
    console.log("USDC whitelisted for payments");
    
    // Verify deployment
    console.log("Platform fee:", await platform.platformFee());
    console.log("Grace period:", await platform.gracePeriod());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
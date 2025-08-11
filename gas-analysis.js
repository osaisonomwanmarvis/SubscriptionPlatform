async function analyzeGasCosts() {
    const platform = await ethers.getContractAt("SubscriptionPlatform", CONTRACT_ADDRESS);
    
    console.log("=== GAS COST ANALYSIS ===");
    
    // Estimate subscription costs
    const subscribeGas = await platform.estimateGas.subscribe(CREATOR_ADDRESS, 0, {
        value: ethers.utils.parseEther("0.01")
    });
    console.log("Subscribe gas cost:", subscribeGas.toString());
    
    // Estimate token subscription
    const tokenSubscribeGas = await platform.estimateGas.subscribeWithToken(
        CREATOR_ADDRESS, 0, TOKEN_ADDRESS, ethers.utils.parseEther("10")
    );
    console.log("Token subscribe gas cost:", tokenSubscribeGas.toString());
    
    // Calculate costs at different gas prices
    const gasPrices = [10, 20, 50]; // gwei
    gasPrices.forEach(price => {
        const cost = subscribeGas.mul(price).mul(1e9);
        console.log(`At ${price} gwei: ${ethers.utils.formatEther(cost)} ETH`);
    });
}
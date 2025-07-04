import { ethers, network } from "hardhat";
import { getSupportedTokens } from "../config/tokens";
import { getCommonConfig } from "../config/common";

async function main() {
  // Get AssetHandler address from config
  const config = getCommonConfig(network.name);
  const assetHandlerAddress = config.assetHandlerAddress;
  
  if (!assetHandlerAddress) {
    throw new Error("AssetHandler address not found in config");
  }

  console.log(`🌐 Network: ${network.name}`);
  console.log(`🔧 AssetHandler: ${assetHandlerAddress}`);

  const AssetHandler = await ethers.getContractFactory("AssetHandler");
  const assetHandler = AssetHandler.attach(assetHandlerAddress);

  const supportedTokens = getSupportedTokens(network.name);
  
  for (const token of supportedTokens) {
    if (!token.address || token.address === '') {
      console.log(`⚠️ Skipping empty address for token`);
      continue;
    }
    
    try {
      // Check if asset already exists by checking if priceAggregator is set
      const existingAggregator = await assetHandler.priceAggregators(token.address);
      if (existingAggregator !== ethers.ZeroAddress) {
        console.log(`✅ Asset ${token.address} already configured`);
        continue;
      }

      const aggregator = token.aggregator || ethers.ZeroAddress;
      if (aggregator === ethers.ZeroAddress || aggregator === '') {
        console.log(`⚠️ Skipping ${token.address} - no aggregator address`);
        continue;
      }

      const tx = await assetHandler.addAsset(token.address, token.type, aggregator);
      await tx.wait();
      
      console.log(`✅ Asset ${token.address} added with type ${token.type}`);
    } catch (error: any) {
      console.log(`❌ Failed to add ${token.address}:`, error.message || error);
    }
  }
  
  console.log("Asset configuration completed");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

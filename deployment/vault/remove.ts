import { ethers, network } from "hardhat";
import { getCommonConfig } from "../config/common";

async function main() {
  // Get VaultFactory address from config
  const config = getCommonConfig(network.name);
  const vaultFactoryAddress = config.vaultFactoryAddress;
  
  if (!vaultFactoryAddress) {
    throw new Error("vaultFactoryAddress address not found in config");
  }

  console.log(`🌐 Network: ${network.name}`);
  console.log(`🔧 vaultFactory: ${vaultFactoryAddress}`);

  const VaultFactory = await ethers.getContractFactory("VaultFactory");
  const vaultFactory = VaultFactory.attach(vaultFactoryAddress);

  // Get whitelisted assets directly from VaultFactory
  console.log("📋 Getting whitelisted assets from VaultFactory...");
  const whitelistedAssets = await vaultFactory.getWhitelistedAssets();
  
  console.log(`📊 Found ${whitelistedAssets.length} whitelisted assets:`);
  whitelistedAssets.forEach((asset: string, index: number) => {
    console.log(`   ${index + 1}. ${asset}`);
  });
  
  if (whitelistedAssets.length === 0) {
    console.log("ℹ️  No whitelisted assets found. Nothing to remove.");
    return;
  }
  
  console.log("\n🗑️ Removing whitelisted assets...");
  
  for (let i = 0; i < whitelistedAssets.length; i++) {
    const assetAddress = whitelistedAssets[i];
    
    if (!assetAddress || assetAddress === '0x0000000000000000000000000000000000000000') {
      console.log(`⚠️ Skipping invalid address: ${assetAddress}`);
      continue;
    }
    
    console.log(`\n🔄 Processing asset ${i + 1}/${whitelistedAssets.length}: ${assetAddress}`);
    
    try {
      // Remove from whitelist
      console.log(`   📤 Removing from whitelist...`);
      const tx1 = await vaultFactory.removeWhitelistedAsset(assetAddress);
      await tx1.wait();
      console.log(`   ✅ Removed from whitelist: ${tx1.hash}`);

      // Remove from underlying assets
      console.log(`   📤 Removing from underlying assets...`);
      const tx2 = await vaultFactory.removeUnderlyingAsset(assetAddress);
      await tx2.wait();
      console.log(`   ✅ Removed from underlying: ${tx2.hash}`);
      
      console.log(`   🎉 Asset ${assetAddress} completely removed`);
      
    } catch (error: any) {
      console.log(`   ❌ Failed to remove ${assetAddress}:`, error.message || error);
      
      // Continue with next asset even if this one fails
      if (error.message?.includes('not whitelisted')) {
        console.log(`   ℹ️  Asset was not whitelisted, continuing...`);
      } else if (error.message?.includes('not allowed')) {
        console.log(`   ℹ️  Asset was not in underlying assets, continuing...`);
      }
    }
  }
  
  console.log("\n🏁 Asset removal process completed!");
  
  // Verify final state
  console.log("\n📋 Checking final state...");
  const finalWhitelistedAssets = await vaultFactory.getWhitelistedAssets();
  console.log(`📊 Remaining whitelisted assets: ${finalWhitelistedAssets.length}`);
  
  if (finalWhitelistedAssets.length > 0) {
    console.log("📋 Remaining assets:");
    finalWhitelistedAssets.forEach((asset: string, index: number) => {
      console.log(`   ${index + 1}. ${asset}`);
    });
  } else {
    console.log("✅ All assets successfully removed from whitelist");
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

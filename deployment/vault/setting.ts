import { ethers, network } from "hardhat";
import { getSupportedTokens } from "../config/tokens";
import { getCommonConfig } from "../config/common";

async function main() {
  // Get VaultFactory address from config
  const config = getCommonConfig(network.name);
  const vaultFactoryAddress = config.vaultFactoryAddress;
  
  if (!vaultFactoryAddress) {
    throw new Error("VaultFactory address not found in config");
  }

  console.log(`🌐 Network: ${network.name}`);
  console.log(`🏭 VaultFactory: ${vaultFactoryAddress}`);

  const VaultFactory = await ethers.getContractFactory("VaultFactory");
  const vaultFactory = VaultFactory.attach(vaultFactoryAddress);

  const supportedTokens = getSupportedTokens(network.name);
  
  console.log(`\n📋 Whitelisting ${supportedTokens.length} assets...`);

  for (const token of supportedTokens) {
    if (!token.address || token.address === '') {
      console.log(`⚠️ Skipping empty address for token`);
      continue;
    }
    
    // Special handling for native ETH (address(0))
    if (token.address === ethers.ZeroAddress && token.type !== 2) {
      console.log(`⚠️ Skipping address(0) - not NativeTokenType`);
      continue;
    }
    
    try {
      // Check if asset is already whitelisted
      const isWhitelisted = await vaultFactory.isAssetWhitelisted(token.address);
      if (!isWhitelisted) {
        // Add to whitelist (can be held in vaults)
        const tx1 = await vaultFactory.addWhitelistedAsset(token.address, token.type);
        await tx1.wait();
        console.log(`✅ Whitelisted asset ${token.address} (type: ${token.type})`);
      } else {
        console.log(`✅ Asset ${token.address} already whitelisted`);
      }

      // Check underlying asset logic regardless of whitelist status
      if (token.isUnderlying) {
        try {
          const isUnderlyingAllowed = await vaultFactory.isUnderlyingAssetAllowed(token.address);
          if (!isUnderlyingAllowed) {
            const tx2 = await vaultFactory.addUnderlyingAsset(token.address, token.type);
            await tx2.wait();
            console.log(`🔗 Added ${token.address} as underlying asset`);
          } else {
            console.log(`🔗 Asset ${token.address} already allowed as underlying`);
          }
        } catch (error: any) {
          console.log(`⚠️ Could not add ${token.address} as underlying:`, error.message || error);
        }
      } else {
        console.log(`⚪ Asset ${token.address} configured as whitelist-only (not underlying)`);
      }

    } catch (error: any) {
      console.log(`❌ Failed to process ${token.address}:`, error.message || error);
    }
  }

  console.log(`\n📊 Getting whitelist summary...`);
  
  try {
    const whitelistedAssets = await vaultFactory.getWhitelistedAssets();
    const underlyingAssets = await vaultFactory.getUnderlyingAssets();
    
    console.log(`\n✅ Asset configuration completed!`);
    console.log(`📝 Whitelisted assets (${whitelistedAssets.length}):`);
    whitelistedAssets.forEach((asset: string, index: number) => {
      console.log(`   ${index + 1}. ${asset}`);
    });
    
    console.log(`\n🔗 Underlying assets (${underlyingAssets.length}):`);
    underlyingAssets.forEach((asset: string, index: number) => {
      console.log(`   ${index + 1}. ${asset}`);
    });
    
  } catch (error: any) {
    console.log(`⚠️ Could not fetch summary:`, error.message || error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 
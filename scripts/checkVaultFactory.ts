import { ethers, network } from "hardhat";
import { getCommonConfig } from "../deployment/config/common";

// Hardhat task arguments are passed as the last argument to the main function
async function main() {
  // Get config from common.ts
  const config = getCommonConfig(network.name);
  const { vaultFactoryAddress } = config;
  
  if (!vaultFactoryAddress) {
    throw new Error("VaultFactory address not found in config");
  }

  console.log(`=== VAULT FACTORY INFO ===`);
  console.log(`Network: ${network.name}`);
  console.log(`VaultFactory: ${vaultFactoryAddress}`);

  // Connect to VaultFactory
  const vaultFactory = await ethers.getContractAt("VaultFactory", vaultFactoryAddress);
  
  // Get owner
  const owner = await vaultFactory.owner();
  console.log(`\n👤 Owner: ${owner}`);
  
  // Get implementation
  const implementation = await vaultFactory.vaultImplementation();
  console.log(`📝 Current Implementation: ${implementation}`);
  
  const version = await vaultFactory.implementationVersion();
  console.log(`📊 Implementation Version: ${version}`);

  // For testing different vaults, change this address
  const vaultAddress = '0xecBd6EE3cd0B77648a1350eE87BC45C1e1D38F09';
  console.log(`\n🔍 Checking vault: ${vaultAddress}`);
  
  try {
    // Check if vault exists
    const isVault = await vaultFactory.isVault(vaultAddress);
    console.log(`✅ Is registered vault: ${isVault}`);
    
    if (isVault) {
      // Get vault manager
      const manager = await vaultFactory.vaultManager(vaultAddress);
      console.log(`👤 Manager: ${manager}`);
      
      // Get vault version
      const vaultVersion = await vaultFactory.vaultVersion(vaultAddress);
      console.log(`📊 Vault Version: ${vaultVersion}`);
      
      // Try to get vault info
      try {
        const vaultInfo = await vaultFactory.getVaultInfo(vaultAddress);
        console.log(`\n📋 Vault Info:`);
        console.log(`   Manager: ${vaultInfo.manager}`);
        console.log(`   Underlying Asset: ${vaultInfo.underlyingAsset}`);
        console.log(`   Total Assets: ${ethers.formatEther(vaultInfo.totalAssets)} ETH`);
        console.log(`   Total Supply: ${ethers.formatEther(vaultInfo.totalSupply)} shares`);
        console.log(`   Max Capacity: ${ethers.formatEther(vaultInfo.maxCapacity)} ETH`);
        console.log(`   Is Paused: ${vaultInfo.isPaused}`);
        console.log(`   Share Price: ${ethers.formatEther(vaultInfo.sharePrice)} ETH per share`);
      } catch (error: any) {
        console.log(`❌ Error getting vault info: ${error.message}`);
      }
    } else {
      console.log(`❌ This address is not registered as a vault in the factory!`);
    }
    
    // Get all deployed vaults
    const deployedVaults = await vaultFactory.getDeployedVaults();
    console.log(`\n📊 Total Deployed Vaults: ${deployedVaults.length}`);
    console.log(`Deployed Vaults:`);
    
    for (let i = 0; i < deployedVaults.length; i++) {
      console.log(`   ${i + 1}. ${deployedVaults[i]}`);
    }
    
  } catch (error: any) {
    console.log(`❌ Error: ${error.message}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 
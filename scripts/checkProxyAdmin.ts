import { ethers, network } from "hardhat";
import { getCommonConfig } from "../deployment/config/common";

async function main() {
  // Get config from common.ts
  const config = getCommonConfig(network.name);
  const { vaultFactoryAddress } = config;
  
  if (!vaultFactoryAddress) {
    throw new Error("VaultFactory address not found in config");
  }

  console.log(`=== PROXY ADMIN INFO ===`);
  console.log(`Network: ${network.name}`);
  console.log(`VaultFactory: ${vaultFactoryAddress}`);

  // Connect to VaultFactory
  const vaultFactory = await ethers.getContractAt("VaultFactory", vaultFactoryAddress);
  
  // Get ProxyAdmin address
  const proxyAdminAddress = await vaultFactory.proxyAdmin();
  console.log(`\n📋 ProxyAdmin Address: ${proxyAdminAddress}`);
  
  // Connect to ProxyAdmin
  const proxyAdminABI = [
    "function owner() view returns (address)",
    "function getProxyAdmin(address proxy) view returns (address)",
    "function getProxyImplementation(address proxy) view returns (address)",
    "function changeProxyAdmin(address proxy, address newAdmin) external",
    "function upgrade(address proxy, address implementation) external",
    "function upgradeAndCall(address proxy, address implementation, bytes memory data) external payable"
  ];
  
  const proxyAdmin = new ethers.Contract(proxyAdminAddress, proxyAdminABI, await ethers.provider.getSigner());
  
  try {
    // Get ProxyAdmin owner
    const owner = await proxyAdmin.owner();
    console.log(`👤 ProxyAdmin Owner: ${owner}`);
    
    // Get deployed vaults
    const deployedVaults = await vaultFactory.getDeployedVaults();
    console.log(`\n📊 Total Deployed Vaults: ${deployedVaults.length}`);
    
    // Check implementation for each vault
    console.log(`\n📋 Vault Implementations:`);
    for (let i = 0; i < deployedVaults.length; i++) {
      const vaultAddress = deployedVaults[i];
      try {
        const implementation = await proxyAdmin.getProxyImplementation(vaultAddress);
        console.log(`   ${i + 1}. Vault: ${vaultAddress}`);
        console.log(`      Implementation: ${implementation}`);
        
        // Get vault manager
        const manager = await vaultFactory.vaultManager(vaultAddress);
        console.log(`      Manager: ${manager}`);
      } catch (error: any) {
        console.log(`   ${i + 1}. Vault: ${vaultAddress}`);
        console.log(`      ❌ Error getting implementation: ${error.message}`);
      }
    }
    
    // Get current factory implementation
    const currentImpl = await vaultFactory.vaultImplementation();
    console.log(`\n📝 Current Factory Implementation: ${currentImpl}`);
    
  } catch (error: any) {
    console.log(`❌ Error: ${error.message}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 
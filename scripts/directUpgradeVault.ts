import { ethers, network } from "hardhat";
import { getCommonConfig } from "../deployment/config/common";

async function main() {
  // Get config from common.ts
  const config = getCommonConfig(network.name);
  const { vaultFactoryAddress } = config;
  
  if (!vaultFactoryAddress) {
    throw new Error("VaultFactory address not found in config");
  }

  console.log(`=== DIRECT VAULT UPGRADE ===`);
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
  
  // Get ProxyAdmin owner
  const owner = await proxyAdmin.owner();
  console.log(`👤 ProxyAdmin Owner: ${owner}`);
  
  // Get current implementation from factory
  const currentImpl = await vaultFactory.vaultImplementation();
  console.log(`📝 Current Factory Implementation: ${currentImpl}`);
  
  // Target vault to upgrade
  const vaultAddress = '0xecBd6EE3cd0B77648a1350eE87BC45C1e1D38F09';
  console.log(`\n🏦 Target Vault: ${vaultAddress}`);
  
  // Check if vault exists in factory
  const isVault = await vaultFactory.isVault(vaultAddress);
  if (!isVault) {
    throw new Error(`Address ${vaultAddress} is not a valid vault in this factory!`);
  }
  
  // Get vault manager
  const manager = await vaultFactory.vaultManager(vaultAddress);
  console.log(`👤 Manager: ${manager}`);
  
  // Try to get current implementation
  try {
    const implementation = await proxyAdmin.getProxyImplementation(vaultAddress);
    console.log(`📝 Current Implementation: ${implementation}`);
  } catch (error: any) {
    console.log(`❌ Error getting implementation: ${error.message}`);
    console.log(`   This is expected if the proxy is not a TransparentUpgradeableProxy`);
  }
  
  // Check if the vault is a proxy at all
  try {
    // Try to access the implementation slot directly
    const implementationSlot = '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc';
    const implementationData = await ethers.provider.getStorage(vaultAddress, implementationSlot);
    console.log(`📝 Implementation Slot Data: ${implementationData}`);
    
    // Convert the data to an address (remove leading zeros)
    const implementationAddress = ethers.getAddress('0x' + implementationData.slice(26));
    console.log(`📝 Implementation Address: ${implementationAddress}`);
    
    // Check if the implementation matches the current factory implementation
    if (implementationAddress.toLowerCase() === currentImpl.toLowerCase()) {
      console.log(`✅ Implementation matches current factory implementation`);
    } else {
      console.log(`⚠️ Implementation does not match current factory implementation`);
    }
  } catch (error: any) {
    console.log(`❌ Error checking implementation slot: ${error.message}`);
  }
  
  // Attempt to upgrade the vault
  try {
    console.log(`\n⏫ Attempting direct upgrade...`);
    
    // Get the signer
    const [signer] = await ethers.getSigners();
    console.log(`👤 Signer: ${await signer.getAddress()}`);
    
    // Check if signer is the owner of the ProxyAdmin
    if ((await signer.getAddress()).toLowerCase() !== owner.toLowerCase()) {
      throw new Error(`Signer is not the owner of the ProxyAdmin. Owner: ${owner}, Signer: ${await signer.getAddress()}`);
    }
    
    // Attempt to upgrade the proxy directly
    const tx = await proxyAdmin.upgrade(vaultAddress, currentImpl, {
      gasLimit: 1000000 // Set a higher gas limit for safety
    });
    
    console.log(`📋 Transaction sent: ${tx.hash}`);
    await tx.wait();
    console.log(`✅ Vault upgraded successfully!`);
    
    // Try to get the new implementation
    try {
      const newImplementation = await proxyAdmin.getProxyImplementation(vaultAddress);
      console.log(`📝 New Implementation: ${newImplementation}`);
    } catch (error: any) {
      console.log(`❌ Error getting new implementation: ${error.message}`);
    }
  } catch (error: any) {
    console.log(`❌ Error upgrading vault: ${error.message}`);
    
    // Try to get more details if available
    if (error.data) {
      console.log(`Error data: ${error.data}`);
    }
    
    if (error.transaction) {
      console.log(`Transaction: ${JSON.stringify(error.transaction)}`);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 
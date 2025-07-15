import { ethers, run, network } from "hardhat";
import { getCommonConfig } from "../config/common";

async function main() {
  // Parse command line arguments
  const args = process.argv.slice(2);
  let vaultAddress = '0xecBd6EE3cd0B77648a1350eE87BC45C1e1D38F09'; // Change to first vault
  let useCurrentImpl = true; // Use current implementation
  
  // Check for --vault and --use-current-impl parameters
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--vault' && i + 1 < args.length) {
      vaultAddress = args[i + 1];
    }
    if (args[i] === '--use-current-impl') {
      useCurrentImpl = true;
    }
    if (args[i] === '--new-impl') {
      useCurrentImpl = false;
    }
  }
  
  // If no vault address provided, use default
  if (!vaultAddress) {
    vaultAddress = '0xecBd6EE3cd0B77648a1350eE87BC45C1e1D38F09';
    console.log(`⚠️ No vault address provided, using default: ${vaultAddress}`);
    console.log(`   Usage: npm run upgrade:vault -- --vault <vault_address> [--use-current-impl]`);
  }

  // Get config from common.ts
  const config = getCommonConfig(network.name);
  const { vaultFactoryAddress } = config;
  
  if (!vaultFactoryAddress) {
    throw new Error("VaultFactory address not found in config");
  }

  console.log(`🚀 Upgrade Vault Implementation`);
  console.log(`🌐 Network: ${network.name}`);
  console.log(`🏭 VaultFactory: ${vaultFactoryAddress}`);
  console.log(`🏦 Target Vault: ${vaultAddress}`);

  // Connect to VaultFactory
  const vaultFactory = await ethers.getContractAt("VaultFactory", vaultFactoryAddress);
  
  // Check current implementation
  const currentImpl = await vaultFactory.vaultImplementation();
  console.log(`📋 Current Factory Implementation: ${currentImpl}`);

  // Check if caller is owner
  const owner = await vaultFactory.owner();
  const [signer] = await ethers.getSigners();
  const signerAddress = await signer.getAddress();
  
  console.log(`👤 Factory Owner: ${owner}`);
  console.log(`👤 Signer: ${signerAddress}`);
  
  if (owner.toLowerCase() !== signerAddress.toLowerCase()) {
    throw new Error(`Only factory owner can upgrade vaults. Current owner: ${owner}, Signer: ${signerAddress}`);
  }

  // Validate vault exists
  const isVault = await vaultFactory.isVault(vaultAddress);
  if (!isVault) {
    throw new Error(`Address ${vaultAddress} is not a valid vault in this factory!`);
  }

  let newImplementationAddress;

  if (useCurrentImpl) {
    // Use current implementation from factory
    console.log(`🔄 Using current factory implementation: ${currentImpl}`);
    if (currentImpl === ethers.ZeroAddress) {
      throw new Error("Current implementation is zero address. Deploy a new implementation first or remove --use-current-impl flag.");
    }
    newImplementationAddress = currentImpl;
  } else {
    // Deploy new implementation
    console.log(`🏗️ Deploying new implementation...`);
    const Vault = await ethers.getContractFactory("Vault");
    const newImplementation = await Vault.deploy();
    await newImplementation.waitForDeployment();
    newImplementationAddress = await newImplementation.getAddress();
    console.log(`📝 New Implementation: ${newImplementationAddress}`);
  }

  // Upgrade specific vault using VaultFactory's upgradeVault method
  console.log(`⏫ Upgrading vault...`);
  
  try {
    // Check if proxyAdmin is set
    const proxyAdmin = await vaultFactory.proxyAdmin();
    console.log(`📋 ProxyAdmin: ${proxyAdmin}`);
    
    // Try to get the vault's current implementation
    try {
      // We need to use a lower-level call to check the implementation
      const adminContract = await ethers.getContractAt("ProxyAdmin", proxyAdmin);
      const currentVaultImpl = await adminContract.getProxyImplementation(vaultAddress);
      console.log(`📋 Current Vault Implementation: ${currentVaultImpl}`);
    } catch (error: any) {
      console.log(`❌ Error getting current vault implementation: ${error.message}`);
    }
    
    console.log(`📋 Attempting to upgrade with implementation: ${newImplementationAddress}`);
    const tx = await vaultFactory.upgradeVault(vaultAddress, newImplementationAddress, {
      gasLimit: 1000000 // Set a higher gas limit for safety
    });
    
    console.log(`📋 Transaction sent: ${tx.hash}`);
    await tx.wait();
    console.log(`✅ Vault upgraded successfully!`);
  } catch (error: any) {
    console.log(`❌ Error upgrading vault: ${error.message}`);
    
    // Try to get more details if available
    if (error.data) {
      console.log(`Error data: ${error.data}`);
    }
    
    if (error.transaction) {
      console.log(`Transaction: ${JSON.stringify(error.transaction)}`);
    }
    
    throw error; // Re-throw to exit with error code
  }

  // Only verify if we deployed a new implementation
  if (!useCurrentImpl && network.name !== "localhost") {
    console.log("Sleeping for 61 seconds before verification...");
    await new Promise((resolve) => setTimeout(resolve, 61000));
    await run("verify:verify", {
      address: newImplementationAddress,
    });
    console.log(`✅ Implementation verified!`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

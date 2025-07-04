import { ethers, run, network } from "hardhat";
import { getCommonConfig } from "../config/common";

async function main() {
  console.log(`🚀 Deploy Vault Implementation`);
  console.log(`🌐 Network: ${network.name}`);
  console.log(`===============================\n`);

  // Get config from common.ts
  const config = getCommonConfig(network.name);
  const { vaultFactoryAddress } = config;
  
  if (!vaultFactoryAddress) {
    throw new Error("VaultFactory address not found in config");
  }

  console.log(`🏭 VaultFactory: ${vaultFactoryAddress}`);
  
  const [deployer] = await ethers.getSigners();
  console.log(`👤 Deployer: ${deployer.address}`);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`💰 Balance: ${ethers.formatEther(balance)} ETH\n`);

  // Connect to VaultFactory
  const vaultFactory = await ethers.getContractAt("VaultFactory", vaultFactoryAddress);
  
  // Check current implementation
  console.log(`📋 Current Factory State:`);
  const owner = await vaultFactory.owner();
  const currentImpl = await vaultFactory.vaultImplementation();
  const version = await vaultFactory.implementationVersion();
  
  console.log(`   Owner: ${owner}`);
  console.log(`   Current Implementation: ${currentImpl}`);
  console.log(`   Implementation Version: ${version}`);
  
  if (deployer.address !== owner) {
    console.log(`❌ Only factory owner can deploy implementation`);
    console.log(`   Current owner: ${owner}`);
    console.log(`   Deployer: ${deployer.address}`);
    return;
  }

  if (currentImpl !== ethers.ZeroAddress) {
    console.log(`⚠️  Implementation already exists: ${currentImpl}`);
    console.log(`   Deploying new implementation will increment version\n`);
  } else {
    console.log(`✅ No implementation set, deploying first one\n`);
  }

  // Deploy Vault Implementation
  console.log(`🏗️  Deploying Vault Implementation...`);
  const Vault = await ethers.getContractFactory("Vault");
  
  const vaultImplementation = await Vault.deploy();
  await vaultImplementation.waitForDeployment();
  
  const vaultImplAddress = await vaultImplementation.getAddress();
  console.log(`✅ Vault Implementation deployed: ${vaultImplAddress}`);

  // Set implementation in factory
  console.log(`\n🔧 Setting Implementation in VaultFactory...`);
  const tx = await vaultFactory.updateVaultImplementation(vaultImplAddress);
  console.log(`📡 Transaction sent: ${tx.hash}`);
  
  const receipt = await tx.wait();
  console.log(`✅ Transaction confirmed in block: ${receipt.blockNumber}`);
  console.log(`⛽ Gas used: ${receipt.gasUsed.toString()}`);

  // Verify the update
  const newImpl = await vaultFactory.vaultImplementation();
  const newVersion = await vaultFactory.implementationVersion();
  
  console.log(`\n✅ Implementation Update Verification:`);
  console.log(`   New Implementation: ${newImpl}`);
  console.log(`   New Version: ${newVersion}`);
  console.log(`   Update Successful: ${newImpl === vaultImplAddress}`);

  if (newImpl === vaultImplAddress) {
    console.log(`\n🎉 Vault Implementation Successfully Deployed & Set!`);
    console.log(`========================================================`);
    console.log(`🔗 Implementation Address: ${vaultImplAddress}`);
    console.log(`📊 Version: ${newVersion}`);
    console.log(`🏭 Factory: ${vaultFactoryAddress}`);
    
    console.log(`\n📝 Update common.ts with:`);
    console.log(`vaultImplementationAddress: '${vaultImplAddress}',`);
    
    console.log(`\n✅ Factory is now ready to create vaults!`);
  } else {
    console.log(`\n❌ Implementation update failed!`);
    process.exit(1);
  }

  // Verify on Etherscan (if not localhost)
  if (network.name !== "localhost") {
    console.log(`\n🔍 Verifying on Etherscan...`);
    console.log("Sleeping for 61 seconds...");
    await new Promise((resolve) => setTimeout(resolve, 61000));
    
    try {
      await run("verify:verify", {
        address: vaultImplAddress,
      });
      console.log(`✅ Contract verified on Etherscan`);
    } catch (error) {
      console.log(`⚠️  Verification failed: ${error}`);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 
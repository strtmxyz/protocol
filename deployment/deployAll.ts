import { ethers, run, network, upgrades } from "hardhat";
import { getCommonConfig } from "./config/common";

async function main() {
  console.log(`🚀 Stratum Protocol - Full Deployment`);
  console.log(`🌐 Network: ${network.name}`);
  console.log(`=======================================\n`);

  const [deployer] = await ethers.getSigners();
  console.log(`👤 Deployer: ${deployer.address}`);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`💰 Balance: ${ethers.formatEther(balance)} ETH\n`);

  if (balance === 0n) {
    throw new Error("❌ Deployer has no ETH balance");
  }

  const deployedContracts: { [key: string]: string } = {};

  try {
    // Step 1: Deploy Governance
    console.log(`📋 Step 1: Deploying Governance...`);
    const Governance = await ethers.getContractFactory("Governance");
    const governance = await upgrades.deployProxy(Governance, []);
    
    const governanceAddress = await governance.getAddress();
    deployedContracts.governance = governanceAddress;
    console.log(`   ✅ Governance: ${governanceAddress}\n`);

    // Step 2: Deploy AssetHandler
    console.log(`🔧 Step 2: Deploying AssetHandler...`);
    const AssetHandler = await ethers.getContractFactory("AssetHandler");
    const assetHandler = await upgrades.deployProxy(AssetHandler, [[]]);
    
    const assetHandlerAddress = await assetHandler.getAddress();
    deployedContracts.assetHandler = assetHandlerAddress;
    console.log(`   ✅ AssetHandler: ${assetHandlerAddress}\n`);

    // Step 3: Deploy VaultFactory
    console.log(`🏭 Step 3: Deploying VaultFactory...`);
    const VaultFactory = await ethers.getContractFactory("VaultFactory");
    const vaultFactory = await upgrades.deployProxy(
      VaultFactory, 
      [assetHandlerAddress, governanceAddress, governanceAddress] // treasury = governance
    );
    
    const vaultFactoryAddress = await vaultFactory.getAddress();
    deployedContracts.vaultFactory = vaultFactoryAddress;
    console.log(`   ✅ VaultFactory: ${vaultFactoryAddress}\n`);

    // Step 4: Deploy Vault Implementation
    console.log(`🏗️  Step 4: Deploying Vault Implementation...`);
    const Vault = await ethers.getContractFactory("Vault");
    const vaultImpl = await Vault.deploy();
    await vaultImpl.waitForDeployment();
    
    const vaultImplAddress = await vaultImpl.getAddress();
    deployedContracts.vaultImplementation = vaultImplAddress;
    console.log(`   ✅ Vault Implementation: ${vaultImplAddress}`);

    // Set implementation in factory
    console.log(`   🔗 Setting implementation in factory...`);
    const setImplTx = await vaultFactory.setVaultImplementation(vaultImplAddress);
    await setImplTx.wait();
    console.log(`   ✅ Implementation set in factory\n`);

    // Step 5: Deploy Guards (if network config exists)
    const config = getCommonConfig(network.name);
    if (config.wETH && config.wETH !== '0x0000000000000000000000000000000000000000') {
      console.log(`🛡️  Step 5: Deploying Guards...`);
      
      // Deploy ERC20Guard
      console.log(`   📄 Deploying ERC20Guard...`);
      const ERC20Guard = await ethers.getContractFactory("ERC20Guard");
      const erc20Guard = await upgrades.deployProxy(ERC20Guard, [config.wETH]);
      const erc20GuardAddress = await erc20Guard.getAddress();
      deployedContracts.erc20Guard = erc20GuardAddress;
      console.log(`   ✅ ERC20Guard: ${erc20GuardAddress}`);

      // Deploy ETHGuard
      console.log(`   💎 Deploying ETHGuard...`);
      const ETHGuard = await ethers.getContractFactory("ETHGuard");
      const ethGuard = await upgrades.deployProxy(ETHGuard, [config.wETH]);
      const ethGuardAddress = await ethGuard.getAddress();
      deployedContracts.ethGuard = ethGuardAddress;
      console.log(`   ✅ ETHGuard: ${ethGuardAddress}\n`);
    }

    // Summary
    console.log(`🎉 Deployment Completed Successfully!`);
    console.log(`=====================================`);
    console.log(`\n📋 Deployed Contracts:`);
    Object.entries(deployedContracts).forEach(([name, address]) => {
      console.log(`   ${name}: ${address}`);
    });

    console.log(`\n📝 Update common.ts with these addresses:`);
    console.log(`case "${network.name}":`);
    console.log(`    return {`);
    console.log(`        // ... existing config ...`);
    console.log(`        governanceAddress: '${deployedContracts.governance}',`);
    console.log(`        assetHandlerAddress: '${deployedContracts.assetHandler}',`);
    console.log(`        vaultFactoryAddress: '${deployedContracts.vaultFactory}',`);
    if (deployedContracts.vaultImplementation) {
      console.log(`        vaultImplementationAddress: '${deployedContracts.vaultImplementation}',`);
    }
    console.log(`    }`);

    // Verification
    if (network.name !== "localhost" && network.name !== "hardhat") {
      console.log(`\n🔍 Verifying contracts on block explorer...`);
      console.log("Sleeping for 61 seconds...");
      await new Promise((resolve) => setTimeout(resolve, 61000));

      const contractsToVerify = [
        { name: "Governance", address: deployedContracts.governance },
        { name: "AssetHandler", address: deployedContracts.assetHandler },
        { name: "VaultFactory", address: deployedContracts.vaultFactory },
        { name: "Vault Implementation", address: deployedContracts.vaultImplementation },
      ];

      if (deployedContracts.erc20Guard) {
        contractsToVerify.push({ name: "ERC20Guard", address: deployedContracts.erc20Guard });
      }
      if (deployedContracts.ethGuard) {
        contractsToVerify.push({ name: "ETHGuard", address: deployedContracts.ethGuard });
      }

      for (const contract of contractsToVerify) {
        try {
          console.log(`   🔍 Verifying ${contract.name}...`);
          await run("verify:verify", {
            address: contract.address,
          });
          console.log(`   ✅ ${contract.name} verified`);
        } catch (error) {
          console.log(`   ⚠️  ${contract.name} verification failed: ${error}`);
        }
      }
    }

    console.log(`\n🎯 Next Steps:`);
    console.log(`1. Update common.ts with deployed addresses`);
    console.log(`2. Run asset configuration: npm run config:assets -- --network ${network.name}`);
    console.log(`3. Run governance configuration: npm run config:governance -- --network ${network.name}`);
    console.log(`4. Create your first vault!`);

  } catch (error) {
    console.error(`❌ Deployment failed:`, error);
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 
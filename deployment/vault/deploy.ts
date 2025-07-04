import { ethers, run, network, upgrades } from "hardhat";
import { getCommonConfig } from "../config/common";

async function main() {
  // Get config from common.ts
  const config = getCommonConfig(network.name);
  const { governanceAddress, assetHandlerAddress } = config;
  const treasuryAddress = "0xA9150Efe8aB3fa0aa66bC06BB8048168e73AD08D"; // Using governance as treasury
  
  console.log(`🌐 Network: ${network.name}`);
  console.log(`📋 Governance: ${governanceAddress}`);
  console.log(`🔧 AssetHandler: ${assetHandlerAddress}`);
  console.log(`💰 Treasury: ${treasuryAddress}`);
  
  if (!governanceAddress || !assetHandlerAddress) {
    throw new Error("Missing required addresses in config");
  }

  const VaultFactory = await ethers.getContractFactory("VaultFactory");
  const vaultFactory = await upgrades.deployProxy(
    VaultFactory, 
    [assetHandlerAddress, treasuryAddress, governanceAddress]
  );

  const vaultFactoryAddress = await vaultFactory.getAddress();

  console.log(`\n✅ VaultFactory deployed successfully!`);
  console.log(`🏭 VaultFactory: ${vaultFactoryAddress}`);
  console.log(`\n📝 Update common.ts with:`);
  console.log(`vaultFactoryAddress: '${vaultFactoryAddress}',`);

  if(network.name !== "localhost") {
    console.log("Sleeping for 61 seconds...");
    await new Promise((resolve) => setTimeout(resolve, 61000));
    await run("verify:verify", {
      address: vaultFactoryAddress,
    });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 
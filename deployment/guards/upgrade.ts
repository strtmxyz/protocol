import { ethers, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

/**
 * Upgrades a deployed guard contract
 * @param hre Hardhat Runtime Environment
 * @param guardName Name of the guard contract to upgrade (e.g., "AmbientGuard")
 * @param proxyAddress Address of the proxy contract
 * @returns Object containing the upgraded contract instance and address
 */
export async function upgradeGuard(
  hre: HardhatRuntimeEnvironment,
  guardName: string,
  proxyAddress: string
) {
  console.log(`🔄 Upgrading ${guardName}...`);
  
  const [deployer] = await ethers.getSigners();
  console.log("Upgrading with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Validate proxy address
  if (!ethers.isAddress(proxyAddress)) {
    throw new Error(`Invalid proxy address: ${proxyAddress}`);
  }
  
  console.log(`Using proxy address: ${proxyAddress}`);

  // Get contract factory for the guard
  const GuardFactory = await ethers.getContractFactory(guardName);
  
  // Force import in case the proxy wasn't properly registered in the Upgrades plugin
  try {
    await upgrades.forceImport(proxyAddress, GuardFactory);
    console.log("✅ Proxy successfully imported");
  } catch (error) {
    console.log("⚠️ Force import failed, continuing with upgrade:", error);
  }
  
  // Upgrade the proxy to the new implementation
  const upgradedGuard = await upgrades.upgradeProxy(
    proxyAddress, 
    GuardFactory, 
    { 
      redeployImplementation: 'always',
      kind: 'transparent' 
    }
  );

  await upgradedGuard.waitForDeployment();
  const guardAddress = await upgradedGuard.getAddress();

  console.log(`✅ ${guardName} upgraded at address:`, guardAddress);
  
  try {
    console.log("Platform name:", await upgradedGuard.platformName());
  } catch (error) {
    console.log("⚠️ Could not retrieve platform name");
  }

  // Verify on Etherscan if not local network
  const networkName = hre.network.name;
  if (networkName !== "hardhat" && networkName !== "localhost") {
    console.log("🔍 Waiting for block confirmations...");
    // Wait for 5 blocks for transaction confirmation
    await new Promise(resolve => setTimeout(resolve, 60000)); // 60 seconds
    
    try {
      await hre.run("verify:verify", {
        address: guardAddress,
        constructorArguments: [],
      });
      console.log("✅ Contract verified on Etherscan");
    } catch (error) {
      console.log("❌ Verification failed:", error);
    }
  }

  return {
    guard: upgradedGuard,
    guardAddress,
  };
}

// For standalone upgrade execution
async function main() {
  const hre = require("hardhat");
  
  // These values should be provided as command-line arguments or from .env
  const guardName = process.env.GUARD_NAME || 'AmbientGuard';
  const proxyAddress = process.env.PROXY_ADDRESS;
  
  if (!proxyAddress) {
    throw new Error("PROXY_ADDRESS environment variable is required");
  }
  
  await upgradeGuard(hre, guardName, proxyAddress);
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

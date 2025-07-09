import { ethers, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

export async function deployPancakeSwapGuard(hre: HardhatRuntimeEnvironment) {
  console.log("🥞 Deploying PancakeSwapGuard...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Deploy PancakeSwapGuard as upgradeable proxy
  const PancakeSwapGuardFactory = await ethers.getContractFactory("PancakeSwapGuard");
  const pancakeSwapGuard = await upgrades.deployProxy(
    PancakeSwapGuardFactory,
    [], // initialize() takes no parameters
    { initializer: "initialize" }
  );

  await pancakeSwapGuard.waitForDeployment();
  const pancakeSwapGuardAddress = await pancakeSwapGuard.getAddress();

  console.log("✅ PancakeSwapGuard deployed to:", pancakeSwapGuardAddress);
  console.log("Platform name:", await pancakeSwapGuard.platformName());

  // Verify on Etherscan if not local network
  const networkName = hre.network.name;
  if (networkName !== "hardhat" && networkName !== "localhost") {
    console.log("🔍 Waiting for block confirmations...");
    await pancakeSwapGuard.deploymentTransaction()?.wait(5);
    
    try {
      await hre.run("verify:verify", {
        address: pancakeSwapGuardAddress,
        constructorArguments: [],
      });
      console.log("✅ Contract verified on Etherscan");
    } catch (error) {
      console.log("❌ Verification failed:", error);
    }
  }

  return {
    pancakeSwapGuard,
    pancakeSwapGuardAddress,
  };
}

// For standalone deployment
async function main() {
  const hre = require("hardhat");
  await deployPancakeSwapGuard(hre);
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
} 
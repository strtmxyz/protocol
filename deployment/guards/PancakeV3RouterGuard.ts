import { ethers, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

export async function deployPancakeV3RouterGuard(hre: HardhatRuntimeEnvironment) {
  console.log("🥞 Deploying PancakeV3RouterGuard...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Deploy PancakeV3RouterGuard as upgradeable proxy
  const PancakeV3RouterGuardFactory = await ethers.getContractFactory("PancakeV3RouterGuard");
  const pancakeV3RouterGuard = await upgrades.deployProxy(
    PancakeV3RouterGuardFactory,
    [], // initialize() takes no parameters
    { initializer: "initialize" }
  );

  await pancakeV3RouterGuard.waitForDeployment();
  const pancakeV3RouterGuardAddress = await pancakeV3RouterGuard.getAddress();

  console.log("✅ PancakeV3RouterGuard deployed to:", pancakeV3RouterGuardAddress);
  console.log("Platform name:", await pancakeV3RouterGuard.platformName());

  // Verify on Etherscan if not local network
  const networkName = hre.network.name;
  if (networkName !== "hardhat" && networkName !== "localhost") {
    console.log("🔍 Waiting for block confirmations...");
    await pancakeV3RouterGuard.deploymentTransaction()?.wait(5);
    
    try {
      await hre.run("verify:verify", {
        address: pancakeV3RouterGuardAddress,
        constructorArguments: [],
      });
      console.log("✅ Contract verified on Etherscan");
    } catch (error) {
      console.log("❌ Verification failed:", error);
    }
  }

  return {
    pancakeV3RouterGuard,
    pancakeV3RouterGuardAddress,
  };
}

// For standalone deployment
async function main() {
  const hre = require("hardhat");
  await deployPancakeV3RouterGuard(hre);
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
} 
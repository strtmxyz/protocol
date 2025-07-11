import { ethers, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

export async function deployPancakeV2RouterGuard(hre: HardhatRuntimeEnvironment) {
  console.log("🥞 Deploying PancakeV2RouterGuard...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Deploy PancakeV2RouterGuard as upgradeable proxy
  const PancakeV2RouterGuardFactory = await ethers.getContractFactory("PancakeV2RouterGuard");
  const pancakeV2RouterGuard = await upgrades.deployProxy(
    PancakeV2RouterGuardFactory,
    [], // initialize() takes no parameters
    { initializer: "initialize" }
  );

  await pancakeV2RouterGuard.waitForDeployment();
  const pancakeV2RouterGuardAddress = await pancakeV2RouterGuard.getAddress();

  console.log("✅ PancakeV2RouterGuard deployed to:", pancakeV2RouterGuardAddress);
  console.log("Platform name:", await pancakeV2RouterGuard.platformName());

  // Verify on Etherscan if not local network
  const networkName = hre.network.name;
  if (networkName !== "hardhat" && networkName !== "localhost") {
    console.log("🔍 Waiting for block confirmations...");
    await pancakeV2RouterGuard.deploymentTransaction()?.wait(5);
    
    try {
      await hre.run("verify:verify", {
        address: pancakeV2RouterGuardAddress,
        constructorArguments: [],
      });
      console.log("✅ Contract verified on Etherscan");
    } catch (error) {
      console.log("❌ Verification failed:", error);
    }
  }

  return {
    pancakeV2RouterGuard,
    pancakeV2RouterGuardAddress,
  };
}

// For standalone deployment
async function main() {
  const hre = require("hardhat");
  await deployPancakeV2RouterGuard(hre);
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
} 
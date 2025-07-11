import { ethers, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

export async function deployAmbientGuard(hre: HardhatRuntimeEnvironment) {
  console.log("🌊 Deploying AmbientGuard...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Deploy AmbientGuard as upgradeable proxy
  const AmbientGuardFactory = await ethers.getContractFactory("AmbientGuard");
  const ambientGuard = await upgrades.deployProxy(
    AmbientGuardFactory,
    [], // initialize() takes no parameters
    { initializer: "initialize" }
  );

  await ambientGuard.waitForDeployment();
  const ambientGuardAddress = await ambientGuard.getAddress();

  console.log("✅ AmbientGuard deployed to:", ambientGuardAddress);
  console.log("Platform name:", await ambientGuard.platformName());

  // Verify on Etherscan if not local network
  const networkName = hre.network.name;
  if (networkName !== "hardhat" && networkName !== "localhost") {
    console.log("🔍 Waiting for block confirmations...");
    await ambientGuard.deploymentTransaction()?.wait(5);
    
    try {
      await hre.run("verify:verify", {
        address: ambientGuardAddress,
        constructorArguments: [],
      });
      console.log("✅ Contract verified on Etherscan");
    } catch (error) {
      console.log("❌ Verification failed:", error);
    }
  }

  return {
    ambientGuard,
    ambientGuardAddress,
  };
}

// For standalone deployment
async function main() {
  const hre = require("hardhat");
  await deployAmbientGuard(hre);
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
} 
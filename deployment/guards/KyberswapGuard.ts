import { ethers, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

export async function deployKyberswapGuard(hre: HardhatRuntimeEnvironment) {
  console.log("🌀 Deploying KyberswapGuard...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Deploy KyberswapGuard as upgradeable proxy
  const KyberswapGuardFactory = await ethers.getContractFactory("KyberswapGuard");
  const kyberswapGuard = await upgrades.deployProxy(
    KyberswapGuardFactory,
    [], // initialize() takes no parameters
    { initializer: "initialize" }
  );

  await kyberswapGuard.waitForDeployment();
  const kyberswapGuardAddress = await kyberswapGuard.getAddress();

  console.log("✅ KyberswapGuard deployed to:", kyberswapGuardAddress);
  console.log("Platform name:", await kyberswapGuard.platformName());

  // Verify on Etherscan if not local network
  const networkName = hre.network.name;
  if (networkName !== "hardhat" && networkName !== "localhost") {
    console.log("🔍 Waiting for block confirmations...");
    await kyberswapGuard.deploymentTransaction()?.wait(5);
    
    try {
      await hre.run("verify:verify", {
        address: kyberswapGuardAddress,
        constructorArguments: [],
      });
      console.log("✅ Contract verified on Etherscan");
    } catch (error) {
      console.log("❌ Verification failed:", error);
    }
  }

  return {
    kyberswapGuard,
    kyberswapGuardAddress,
  };
}

// For standalone deployment
async function main() {
  const hre = require("hardhat");
  await deployKyberswapGuard(hre);
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
} 
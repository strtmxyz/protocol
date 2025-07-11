import { ethers, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getCommonConfig } from "../config/common";

export async function deployERC20PancakeLPGuard(hre: HardhatRuntimeEnvironment) {
  console.log("🥞 Deploying ERC20PancakeLPGuard...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  const config = getCommonConfig(hre.network.name);
  console.log(`🔧 WETH Address: ${config.wETH}`);
  
  if (!config.wETH) {
    throw new Error("WETH address not found in config");
  }

  // Deploy ERC20PancakeLPGuard as upgradeable proxy
  const ERC20PancakeLPGuardFactory = await ethers.getContractFactory("ERC20PancakeLPGuard");
  const erc20PancakeLPGuard = await upgrades.deployProxy(
    ERC20PancakeLPGuardFactory,
    [config.wETH], // initialize(address _WETH)
    { initializer: "initialize" }
  );

  await erc20PancakeLPGuard.waitForDeployment();
  const erc20PancakeLPGuardAddress = await erc20PancakeLPGuard.getAddress();

  console.log("✅ ERC20PancakeLPGuard deployed to:", erc20PancakeLPGuardAddress);
  console.log("🔧 WETH:", config.wETH);

  // Verify on Etherscan if not local network
  const networkName = hre.network.name;
  if (networkName !== "hardhat" && networkName !== "localhost") {
    console.log("🔍 Waiting for block confirmations...");
    await erc20PancakeLPGuard.deploymentTransaction()?.wait(5);
    
    try {
      await hre.run("verify:verify", {
        address: erc20PancakeLPGuardAddress,
        constructorArguments: [],
      });
      console.log("✅ Contract verified on Etherscan");
    } catch (error) {
      console.log("❌ Verification failed:", error);
    }
  }

  return {
    erc20PancakeLPGuard,
    erc20PancakeLPGuardAddress,
  };
}

// For standalone deployment
async function main() {
  const hre = require("hardhat");
  await deployERC20PancakeLPGuard(hre);
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
} 
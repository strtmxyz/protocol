import { ethers, run, network, upgrades } from "hardhat";
import { getCommonConfig } from "../config/common";

async function main() {
  const config = getCommonConfig(network.name);
  
  console.log(`🚀 Deploying ETHGuard with WETH: ${config.wETH}`);
  
  const ETHGuard = await ethers.getContractFactory("ETHGuard");
  const guard = await upgrades.deployProxy(
    ETHGuard, [config.wETH]
  )

  const deployedAddress = await guard.getAddress()

  console.log(
    `✅ ETHGuard deployed to ${deployedAddress}`
  );

  if(network.name !== "localhost") {
    console.log("⏳ Sleeping for 61 seconds before verification...");
    await new Promise((resolve) => setTimeout(resolve, 61000));
    
    try {
      await run("verify:verify", {
        address: deployedAddress,
      });
      console.log("✅ Contract verified on block explorer");
    } catch (error) {
      console.log("❌ Verification failed:", error);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

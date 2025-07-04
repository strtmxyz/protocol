import { ethers, run, network, upgrades } from "hardhat";
import { getCommonConfig } from "../config/common";

async function main() {
  const config = getCommonConfig(network.name);
  
  console.log(`🌐 Network: ${network.name}`);
  console.log(`🔧 WETH Address: ${config.wETH}`);
  
  if (!config.wETH) {
    throw new Error("WETH address not found in config");
  }
  
  const ERC20Guard = await ethers.getContractFactory("ERC20Guard");
  const erc20Guard = await upgrades.deployProxy(
    ERC20Guard, [config.wETH]
  )

  const deployedAddress = await erc20Guard.getAddress()

  console.log(`\n✅ ERC20Guard deployed successfully!`);
  console.log(`🛡️ ERC20Guard: ${deployedAddress}`);
  console.log(`🔧 WETH: ${config.wETH}`);

  if(network.name !== "localhost") {
    console.log("Sleeping for 61 seconds...");
    await new Promise((resolve) => setTimeout(resolve, 61000));
    await run("verify:verify", {
      address: deployedAddress,
    });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

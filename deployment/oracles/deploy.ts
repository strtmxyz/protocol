import { ethers, run, network, upgrades } from "hardhat";

async function main() {
  const AssetHandler = await ethers.getContractFactory("AssetHandler");
  const assetHandler = await upgrades.deployProxy(
    AssetHandler, 
    [[]] // Initialize with empty assets array
  );

  const assetHandlerAddress = await assetHandler.getAddress();

  console.log(
    `AssetHandler deployed to ${assetHandlerAddress}`
  );

  if(network.name !== "localhost") {
    console.log("Sleeping for 61 seconds...");
    await new Promise((resolve) => setTimeout(resolve, 61000));
    await run("verify:verify", {
      address: assetHandlerAddress,
    });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 
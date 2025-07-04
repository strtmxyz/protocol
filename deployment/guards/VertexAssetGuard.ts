import { ethers, run, network, upgrades } from "hardhat";

async function main() {
  console.log("🚀 Deploying VertexAssetGuard...");
  
  // Get contract factory for VertexAssetGuard
  const smartContractName = "VertexAssetGuard";
  const SmartContractFactory = await ethers.getContractFactory(smartContractName);

  // Deploy proxy contract with Transparent upgrade pattern
  const deployedSmartContract = await upgrades.deployProxy(
    SmartContractFactory, 
    [], // No constructor arguments needed
    { 
      initializer: "initialize" // Initialize function to call after deployment
    }
  )

  // Get deployed contract address
  const deployedAddress = await deployedSmartContract.getAddress()

  console.log(
    `✅ ${smartContractName} deployed to ${deployedAddress}`
  );

  // Verify contract on block explorer (except for localhost)
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
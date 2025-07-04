import { ethers, network } from "hardhat";
import { Governance } from "../../types";
import { getCommonConfig } from "../config/common";
import { getGovernanceConfig } from "./config";

async function main() {
  console.log("🚀 Configuring Governance guards...");
  
  const config = getCommonConfig(network.name);
  console.log(`📝 Using Governance at: ${config.governanceAddress}`);

  const Governance = await ethers.getContractFactory("Governance");
  const governance = Governance.attach(config.governanceAddress) as unknown as Governance

  const governanceConfig = getGovernanceConfig(network.name)
  
  console.log("🔧 Setting Asset Guards:");
  for(let i = 0; i < governanceConfig.assetGuards.length; i++) {
    const assetGuard = governanceConfig.assetGuards[i]
    console.log(`  - AssetType ${assetGuard.assetType} → ${assetGuard.guardAddress}`);
    const tx = await governance.setAssetGuard(assetGuard.assetType, assetGuard.guardAddress)
    await tx.wait();
    console.log(`    ✅ Tx: ${tx.hash}`);
  }

  console.log("🔧 Setting Contract Guards:");
  for(let i = 0; i < governanceConfig.contractGuards.length; i++) {
    const contractGuard = governanceConfig.contractGuards[i]
    console.log(`  - Contract ${contractGuard.externalAddress} → ${contractGuard.guardAddress}`);
    const tx = await governance.setContractGuard(contractGuard.externalAddress, contractGuard.guardAddress)
    await tx.wait();
    console.log(`    ✅ Tx: ${tx.hash}`);
  }
  
  console.log("✅ Governance configuration completed!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

import { ethers, run, network, upgrades } from "hardhat";

async function main() {
  const Governance = await ethers.getContractFactory("Governance");
  const governance = await upgrades.deployProxy(
    Governance, []
  )

  const governanceAddress = await governance.getAddress()

  console.log(
    `Governance deployed to ${governanceAddress}`
  );

  if(network.name !== "localhost") {
    console.log("Sleeping for 61 seconds...");
    await new Promise((resolve) => setTimeout(resolve, 61000));
    await run("verify:verify", {
      address: governanceAddress,
    });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

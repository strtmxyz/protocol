import { ethers, upgrades, run, network } from "hardhat";

async function main() {
  const guardName = 'AmbientGuard'
  const proxyAddress = '0x0fC052f97029Ce4e744edc31B3e9353F88BD9FC7';
  const SmartContractGuard = await ethers.getContractFactory(guardName);
  await upgrades.forceImport(proxyAddress, SmartContractGuard)
  const guard = await upgrades.upgradeProxy(proxyAddress, SmartContractGuard, {redeployImplementation: 'always'})

  console.log(
    `${guardName} deployed to ${await guard.getAddress()}`
  );

  if(network.name !== "localhost") {
    console.log("Sleeping for 61 seconds...");
    await new Promise((resolve) => setTimeout(resolve, 61000));
    await run("verify:verify", {
      address: await guard.getAddress(),
    });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

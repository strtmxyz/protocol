import { ethers } from "hardhat";
import chalk from "chalk";
import { formatEther, formatUnits } from "ethers";
import { VaultFactory } from "../types/contracts/VaultFactory";
import { Vault } from "../types/contracts/Vault";
import { AssetHandler } from "../types/contracts/utils/AssetHandler";
import { IERC20Metadata } from "../types";

async function main() {
  console.log(chalk.blue("===== Stratum Protocol: VaultFactory Check =====\n"));
  
  // Get the VaultFactory address from env or arguments
  const factoryAddress = process.env.FACTORY_ADDRESS || process.argv[2];
  if (!factoryAddress) {
    throw new Error("Factory address not provided. Set FACTORY_ADDRESS env variable or pass as argument.");
  }

  console.log(chalk.yellow(`🏭 Connecting to VaultFactory at: ${factoryAddress}`));
  
  const factory = await ethers.getContractAt("VaultFactory", factoryAddress) as unknown as VaultFactory;
  
  // Basic Factory Information
  console.log(chalk.green("\n📊 BASIC INFORMATION:"));
  
  const admin = await factory.admin();
  const treasury = await factory.treasury();
  const governance = await factory.governance();
  const proxyAdmin = await factory.proxyAdmin();
  const vaultImplementation = await factory.vaultImplementation();
  const implVersion = await factory.implementationVersion();
  const vaultStorageVersion = await factory.vaultStorageVersion();
  
  console.log(`Admin: ${admin}`);
  console.log(`Treasury: ${treasury}`);
  console.log(`Governance: ${governance}`);
  console.log(`ProxyAdmin: ${proxyAdmin}`);
  console.log(`Vault Implementation: ${vaultImplementation}`);
  console.log(`Implementation Version: ${implVersion}`);
  console.log(`Vault Storage Version: ${vaultStorageVersion}`);
  
  // Factory Configuration
  console.log(chalk.green("\n⚙️ FACTORY CONFIGURATION:"));
  
  const maxCapacityLimit = await factory.maxCapacityLimit();
  const minCapacityLimit = await factory.minCapacityLimit();
  const creationFee = await factory.creationFee();
  
  console.log(`Max Capacity Limit: ${formatEther(maxCapacityLimit)} ETH`);
  console.log(`Min Capacity Limit: ${formatEther(minCapacityLimit)} ETH`);
  console.log(`Creation Fee: ${formatEther(creationFee)} ETH`);
  
  // Asset Handler
  console.log(chalk.green("\n🔄 ASSET HANDLER:"));
  
  // Use direct getAssetHandler method instead of governance mapping
  try {
    const assetHandlerAddress = await factory.getAssetHandler();
    
    if (assetHandlerAddress && assetHandlerAddress !== ethers.ZeroAddress) {
      console.log(`Asset Handler: ${assetHandlerAddress}`);
      
      const assetHandler = await ethers.getContractAt("AssetHandler", assetHandlerAddress) as unknown as AssetHandler;
      console.log(`Chainlink Timeout: ${await assetHandler.chainlinkTimeout()} seconds`);
    } else {
      console.log(chalk.red("❌ Asset Handler not set"));
    }
  } catch (error) {
    console.log(chalk.red(`Error fetching Asset Handler: ${error}`));
  }
  
  // Whitelisted Assets
  console.log(chalk.green("\n💰 WHITELISTED ASSETS:"));
  
  try {
    // Use the getWhitelistedAssets method directly
    const assets = await factory.getWhitelistedAssets();
    const assetCount = assets.length;
    
    console.log(`Total Whitelisted Assets: ${assetCount}`);
    
    for (let i = 0; i < assets.length; i++) {
      const asset = assets[i];
      const tokenType = await factory.tokenType(asset);
      
      let tokenInfo = `${asset} (Type: ${tokenType})`;
      
      // Try to get token name and symbol
      try {
        const token = await ethers.getContractAt("IERC20Metadata", asset) as unknown as IERC20Metadata;
        const name = await token.name();
        const symbol = await token.symbol();
        const decimals = await token.decimals();
        tokenInfo += ` - ${name} (${symbol}), ${decimals} decimals`;
      } catch (error) {
        if (asset === ethers.ZeroAddress) {
          tokenInfo += " - Native Token (ETH)";
        } else {
          tokenInfo += " - Could not retrieve token info";
        }
      }
      
      console.log(`${i+1}. ${tokenInfo}`);
    }
  } catch (error) {
    console.log(chalk.red(`Error fetching whitelisted assets: ${error}`));
  }
  
  // Underlying Assets
  console.log(chalk.green("\n🏦 UNDERLYING ASSETS:"));
  
  try {
    let assetCount = 0;
    let assets = [];
    
    while (true) {
      try {
        const asset = await factory.underlyingAssets(assetCount);
        if (asset === ethers.ZeroAddress) break;
        assets.push(asset);
        assetCount++;
      } catch (error) {
        break;
      }
    }
    
    console.log(`Total Underlying Assets: ${assetCount}`);
    
    for (let i = 0; i < assets.length; i++) {
      const asset = assets[i];
      
      let tokenInfo = `${asset}`;
      
      // Try to get token name and symbol
      try {
        const token = await ethers.getContractAt("IERC20Metadata", asset) as unknown as IERC20Metadata;
        const name = await token.name();
        const symbol = await token.symbol();
        const decimals = await token.decimals();
        
        // Calculate capacity limits for this asset
        const adjustedMaxLimit = await factory.getAdjustedMaxCapacityLimit(asset);
        const adjustedMinLimit = await factory.getAdjustedMinCapacityLimit(asset);
        
        tokenInfo += ` - ${name} (${symbol}), ${decimals} decimals`;
        tokenInfo += `\n   Max Capacity: ${formatUnits(adjustedMaxLimit, decimals)} ${symbol}`;
        tokenInfo += `\n   Min Capacity: ${formatUnits(adjustedMinLimit, decimals)} ${symbol}`;
      } catch (error) {
        tokenInfo += " - Could not retrieve token info";
      }
      
      console.log(`${i+1}. ${tokenInfo}`);
    }
  } catch (error) {
    console.log(chalk.red(`Error fetching underlying assets: ${error}`));
  }
  
  // Deployed Vaults
  console.log(chalk.green("\n🏛️ DEPLOYED VAULTS:"));
  
  try {
    let vaultCount = 0;
    let vaults = [];
    
    while (true) {
      try {
        const vaultAddress = await factory.deployedVaults(vaultCount);
        if (vaultAddress === ethers.ZeroAddress) break;
        vaults.push(vaultAddress);
        vaultCount++;
      } catch (error) {
        break;
      }
    }
    
    console.log(`Total Deployed Vaults: ${vaultCount}`);
    
    // Limit to displaying first 10 vaults to avoid excessive RPC calls
    const displayLimit = Math.min(vaults.length, 10);
    
    for (let i = 0; i < displayLimit; i++) {
      const vaultAddress = vaults[i];
      const manager = await factory.vaultManager(vaultAddress);
      const version = await factory.vaultVersion(vaultAddress);
      
      console.log(`${i+1}. Vault: ${vaultAddress}`);
      console.log(`   Manager: ${manager}`);
      console.log(`   Version: ${version.toString()}`);
      
      // Get more details from the vault itself
      try {
        const vault = await ethers.getContractAt("Vault", vaultAddress) as unknown as Vault;
        
        const underlyingAsset = await vault.underlyingAsset();
        const vaultState = await vault.vaultState();
        const totalAssets = await vault.totalAssets();
        const maxCapacity = await vault.maxCapacity();
        const currentEpoch = await vault.currentEpoch();
        
        // Try to get token info for underlying
        try {
          const token = await ethers.getContractAt("IERC20Metadata", underlyingAsset) as unknown as IERC20Metadata;
          const symbol = await token.symbol();
          const decimals = await token.decimals();
          
          console.log(`   Underlying: ${underlyingAsset} (${symbol})`);
          console.log(`   State: ${mapVaultState(vaultState)}`);
          console.log(`   Total Assets: ${formatUnits(totalAssets, decimals)} ${symbol}`);
          console.log(`   Max Capacity: ${formatUnits(maxCapacity, decimals)} ${symbol}`);
          console.log(`   Current Epoch: ${currentEpoch}`);
        } catch (error) {
          console.log(`   Underlying: ${underlyingAsset}`);
          console.log(`   State: ${mapVaultState(vaultState)}`);
          console.log(`   Total Assets: ${totalAssets}`);
          console.log(`   Max Capacity: ${maxCapacity}`);
          console.log(`   Current Epoch: ${currentEpoch}`);
        }
      } catch (error) {
        console.log(chalk.red(`   Error fetching vault details: ${error}`));
      }
      
      console.log(); // Add newline between vaults
    }
    
    if (vaults.length > displayLimit) {
      console.log(chalk.yellow(`... and ${vaults.length - displayLimit} more vaults (displaying first ${displayLimit} only)`));
    }
    
  } catch (error) {
    console.log(chalk.red(`Error fetching deployed vaults: ${error}`));
  }
}

// Helper function to convert vault state enum to readable string
function mapVaultState(state: bigint): string {
  const states = [
    "FUNDRAISING", // 0
    "LIVE",        // 1
    "PAUSED",      // 2
    "EMERGENCY",   // 3
    "LIQUIDATING", // 4
    "FROZEN"       // 5
  ];
  
  if (state >= 0n && state < BigInt(states.length)) {
    return states[Number(state)];
  } else {
    return `UNKNOWN (${state})`;
  }
}

// Execute the script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(chalk.red("ERROR:"), error);
    process.exit(1);
  }); 
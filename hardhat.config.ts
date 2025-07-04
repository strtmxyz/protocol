import dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import '@typechain/hardhat'
import '@nomicfoundation/hardhat-ethers'
import '@nomicfoundation/hardhat-chai-matchers'
import '@nomicfoundation/hardhat-verify'
import "hardhat-abi-exporter";

dotenv.config();

const config: HardhatUserConfig = {
  paths: {
    sources: "./contracts",
  },
  networks: {
    localhost: {
      chainId: 31337,
      url: "http://127.0.0.1:8545",
      timeout: 600000,
      allowUnlimitedContractSize: true,
      accounts: process.env.OWNER_PRIVATE_KEY ? [process.env.OWNER_PRIVATE_KEY] : [],
    },
    hardhat: {
      allowUnlimitedContractSize: true,
      chainId: 31337,
    },
    arbitrumSepolia : {
      url: 'https://sepolia-rollup.arbitrum.io/rpc',
      chainId: 421614,
      accounts: process.env.OWNER_PRIVATE_KEY
        ?[
          process.env.OWNER_PRIVATE_KEY,
        ]:[],
    },
    sonicBlazeTestnet : {
      url: 'https://rpc.blaze.soniclabs.com',
      chainId: 57054,
      accounts: process.env.OWNER_PRIVATE_KEY
        ?[
          process.env.OWNER_PRIVATE_KEY,
        ]:[],
    },
    sonicMainnet : {
      url: 'https://rpc.soniclabs.com',
      chainId: 146,
      accounts: process.env.OWNER_PRIVATE_KEY
          ?[
              process.env.OWNER_PRIVATE_KEY,
          ]:[],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_V2_API_KEY || ""
  },
  solidity: {
    compilers: [
      {
        version: "0.8.27",
        settings: {
          viaIR: true,
          outputSelection: {
            "*": {
              "*": ["storageLayout"],
            },
          },
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      }
    ]
  },
  typechain: {
    outDir: "./types",
    target: "ethers-v6",
  },
  abiExporter: {
    path: "./abi",
    clear: true,
    flat: true,
    only: [
      "IWETH",
      "IStETH",
      "IAssetGuard",
      "IPlatformGuard",
      "ERC20Guard",
      "ETHGuard",
      "VertexAssetGuard",
      "VertexPlatformGuard",
      "KyberswapGuard",
      "Governance",
      "VaultFactory",
      "Vault",
      "AssetHandler"
    ],
    spacing: 2,
  },
  mocha: {
    timeout: 100000000
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
};

export default config;

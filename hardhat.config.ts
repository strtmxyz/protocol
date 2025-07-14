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
    monadTestnet: {
      url: 'https://testnet-rpc.monad.xyz',
      chainId: 10143,
      accounts: process.env.OWNER_PRIVATE_KEY
        ?[
          process.env.OWNER_PRIVATE_KEY,
        ]:[],
      timeout: 600000, // Increase timeout to 10 minutes
      gasMultiplier: 1.2, // Add 20% to estimated gas
      httpHeaders: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      throwOnCallFailures: false, // Don't throw on call failures
      throwOnTransactionFailures: true,
    },
  },
  sourcify: {
    enabled: true,
    apiUrl: "https://sourcify-api-monad.blockvision.org",
    browserUrl: "https://testnet.monadexplorer.com",
  },
    // To avoid errors from Etherscan
  etherscan: {
    customChains: [
      {
        network: "monadTestnet",
        chainId: 10143,
        urls: {
          apiURL: "https://sourcify-api-monad.blockvision.org/",
          browserURL: "https://explorer.monad.xyz",
        },
      },
    ],
    apiKey: {
      monadTestnet: "SOURCIFY", // giá trị bắt buộc với Sourcify
    },
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
          metadata: {
            bytecodeHash: "none", // disable ipfs
            useLiteralContent: true, // use source code
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
      "AmbientGuard",
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

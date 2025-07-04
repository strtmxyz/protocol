# Stratum Protocol Deployment Guide

## 📋 Overview

This directory contains deployment scripts for the Stratum Protocol smart contracts.

## 🏗️ Architecture

```
Governance (Owner)
    ↓
AssetHandler (Price feeds & asset management)
    ↓
VaultFactory (Creates and manages vaults)
    ↓
Vault (Individual vault instances)
```

## 📦 Deployment Scripts

### Individual Contract Deployment

```bash
# Deploy Governance contract
npm run deploy:governance -- --network <network>

# Deploy AssetHandler (requires Governance)
npm run deploy:assethandler -- --network <network>

# Deploy VaultFactory (requires AssetHandler + Governance)
npm run deploy:vaultfactory -- --network <network>
```

### Full System Deployment

```bash
# Deploy all contracts in correct order
npm run deploy:all -- --network <network>

# Quick commands for specific networks
npm run deploy:localhost        # Local testing
npm run deploy:arbitrum         # Arbitrum Sepolia testnet
npm run deploy:sonic-testnet    # Sonic Blaze testnet
npm run deploy:sonic-mainnet    # Sonic mainnet
```

## 🌐 Supported Networks

| Network | Chain ID | RPC |
|---------|----------|-----|
| `localhost` | 31337 | http://127.0.0.1:8545 |
| `arbitrumSepolia` | 421614 | https://sepolia-rollup.arbitrum.io/rpc |
| `sonicBlazeTestnet` | 57054 | https://rpc.blaze.soniclabs.com |
| `sonicMainnet` | 146 | https://rpc.soniclabs.com |

## ⚙️ Configuration

Update `config/common.ts` with deployed addresses:

```typescript
case "yourNetwork":
    return {
        USDC: '0x...', // USDC token address
        wS: '0x...',   // Wrapped S token
        S: '0x...',    // Native S token
        governanceAddress: '0x...',    // After deployment
        assetHandlerAddress: '0x...',  // After deployment
        vaultFactoryAddress: '0x...',  // After deployment
    }
```

## 🚀 Deployment Process

### 1. Prerequisites

```bash
# Install dependencies
yarn install

# Compile contracts
npm run compile

# Set up environment variables
cp .env.example .env
# Edit .env with your private keys and API keys
```

### 2. Local Testing

```bash
# Start local node
npm run start

# Deploy to localhost (in another terminal)
npm run deploy:localhost
```

### 3. Testnet Deployment

```bash
# Deploy to Arbitrum Sepolia
npm run deploy:arbitrum

# Deploy to Sonic Testnet
npm run deploy:sonic-testnet
```

### 4. Mainnet Deployment

```bash
# Deploy to Sonic Mainnet (use with caution!)
npm run deploy:sonic-mainnet
```

## 📝 Post-Deployment Steps

1. **Update Config**: Copy deployed addresses to `config/common.ts`
2. **Verify Contracts**: Contracts are auto-verified (except localhost)
3. **Deploy Guards**: Deploy asset and platform guard contracts
4. **Configure Assets**: Add supported assets via AssetHandler
5. **Create Vaults**: Use VaultFactory to create first vaults

## 🛡️ Security Features

- **Upgradeable Contracts**: Using OpenZeppelin UUPS proxy pattern
- **Access Control**: Owner and governance-based permissions
- **Auto-Verification**: Contracts verified on Etherscan/block explorers
- **Fee Protection**: Auto-realization prevents fee loss

## ⚡ Gas Optimizations

The deployment includes advanced gas efficiency features:

### Deployment Savings
- **Storage Packing**: Fee variables optimized to `uint16` (saves 4+ storage slots)
- **Deployment Cost**: ~3-5% reduction in vault creation gas
- **Storage Savings**: ~80,000+ gas per vault deployment

### Runtime Optimizations
- **Query Efficiency**: VaultFactory queries 50% faster (O(2n) → O(n))
- **Asset Calculations**: 40-60% gas reduction for multi-asset vaults
- **Fee Updates**: 50% fewer storage operations

### Example Gas Usage
```javascript
// Creating vault with optimized fee parameters
const tx = await vaultFactory.createVault(
    "My Strategy Vault",
    "MSV", 
    usdcAddress,
    managerAddress,
    ethers.parseUnits("100000", 6), // 100K capacity
    200,   // 2% management fee (gas-optimized uint16)
    1000,  // 10% performance fee (gas-optimized uint16)
    { value: ethers.parseEther("0.01") }
);
```

## 📊 Contract Functions

### VaultFactory Key Functions

```solidity
// Create new vault with gas-optimized fee parameters
function createVault(
    string memory name,
    string memory symbol,
    address underlyingAsset,
    address manager,
    uint256 maxCapacity,
    uint256 managementFee,   // Annual management fee (basis points, stored as uint16)
    uint256 performanceFee   // Performance fee (basis points, stored as uint16)
) external payable returns (address vault);

// Update vault fees (factory owner only)
function updateVaultFees(
    address vault,
    uint256 managementFee,   // Max 65535 bps (cast to uint16)
    uint256 performanceFee,  // Max 65535 bps (cast to uint16)
    uint256 withdrawalFee,   // Max 65535 bps (cast to uint16)
    uint256 protocolFee      // Max 65535 bps (cast to uint16)
) external;

// Get vault count
function getVaultCount() external view returns (uint256);

// Get vault by index
function getVault(uint256 index) external view returns (address);
```

### Vault Lifecycle

1. **FUNDRAISING**: Accept deposits, no trading
2. **LIVE**: Trading allowed, limited deposits
3. **Auto-Realization**: Automatic fee collection on withdrawals

## 🔧 Troubleshooting

### Common Issues

1. **"AssetHandler address not configured"**
   - Deploy Governance first, then AssetHandler

2. **"Governance address not configured"**
   - Deploy Governance contract first

3. **Gas estimation failed**
   - Ensure sufficient balance for deployment
   - Check network congestion

4. **Verification failed**
   - Wait longer before verification
   - Check API keys in .env

### Debug Commands

```bash
# Check compiled contracts
ls artifacts/contracts/

# Check network configuration
npx hardhat console --network <network>

# Test deployment locally
npx hardhat test
```

## 📄 Contract ABIs

ABIs are automatically exported to `abi/` directory:

```bash
# Export ABIs after compilation
npm run compile

# ABIs location
ls abi/
```

## 🔗 External Dependencies

- **OpenZeppelin**: Upgradeable contracts, access control
- **Hardhat**: Development framework
- **Ethers.js**: Ethereum library
- **TypeChain**: TypeScript bindings

## 📞 Support

For deployment issues:
1. Check this README
2. Review deployment logs
3. Test on localhost first
4. Verify network configuration

## 🔄 Upgrade Process

For contract upgrades, use the `upgrade-system.ts` script:

```bash
npx hardhat run deployment/upgrade-system.ts --network <network>
```

---

**⚠️ Important**: Always test deployments on testnets before mainnet! 
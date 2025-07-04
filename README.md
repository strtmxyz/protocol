# Stratum Protocol

**Decentralized vault system** for yield farming and asset management with **auto-realization** and **business logic protection**.

## 🎯 Overview

Stratum Protocol provides infrastructure for fund managers to create and manage **investment vaults** with:

- **ERC-4626 Standard**: Full compatibility with vault standard
- **Auto-Realization**: Automatically realize profits when users withdraw to protect fees
- **Epoch-Based Lifecycle**: Clear phases for fundraising and strategy execution
- **Business Logic Protection**: Mandatory complete liquidation before profit realization
- **Multi-Layer Guard System**: Protects strategy execution and asset management
- **Representative Token Support**: Handles staking tokens, LP tokens, yield-bearing assets
- **Upgradeable Architecture**: Proxy pattern for contract upgrades

## 🏗️ Technology Stack

### Core Technologies
- **Solidity 0.8.19**: Smart contracts with custom errors for gas optimization
- **Hardhat**: Development environment and testing framework
- **OpenZeppelin**: Security-audited contract libraries
- **Chainlink**: Price feeds for accurate asset valuation
- **ERC-4626**: Standard vault interface for compatibility

### Architecture Patterns
- **Proxy Pattern**: Upgradeable contracts via TransparentUpgradeableProxy
- **Factory Pattern**: Efficient vault creation and management
- **Guard Pattern**: Modular validation system for external protocols
- **Custom Errors**: Gas-optimized error handling instead of string messages

### Blockchain Support
- **Sonic Blockchain**: Primary deployment target (400K TPS)
- **EVM Compatible**: Works on any EVM-compatible network

## 📋 Project Structure

```
protocol/
├── contracts/
│   ├── Vault.sol              # Main ERC-4626 vault implementation
│   ├── VaultFactory.sol       # Factory for creating vaults
│   ├── Governance.sol         # Protocol governance
│   ├── guards/               # Validation system
│   │   ├── asset/           # Asset-specific guards
│   │   └── platform/        # Protocol-specific guards
│   ├── utils/
│   │   ├── AssetHandler.sol  # Price feeds & asset management
│   │   └── TxDataUtils.sol   # Transaction utilities
│   └── interfaces/          # Contract interfaces
├── deployment/              # Deployment scripts
├── test/                   # Comprehensive test suites
└── types/                  # TypeScript type definitions
```

## 🚀 Key Features

### Auto-Realization System
```solidity
// Automatically realize profits when users withdraw
function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) {
    if (vaultState == VaultState.LIVE) {
        _smartAutoRealize(); // Auto-realize to protect fees
    }
    // ... withdrawal logic
}
```

**Benefits:**
- **Fee Protection**: Prevents fee loss when users withdraw before manual realization
- **Fair Distribution**: Single realization per period serves multiple withdrawals
- **Consistent Treatment**: All users get same treatment within the same realization period

### Guard System
**Asset Guards** - Handle different asset types:
- `ERC20Guard`: Standard tokens (USDC, USDT, etc.)
- `StETHGuard`: Lido staked ETH representative token
- `ETHGuard`: Native ETH handling

**Platform Guards** - Validate external protocol interactions:
- DEX aggregator validation
- Protocol-specific transaction validation

### Vault Lifecycle
1. **FUNDRAISING**: Accept deposits, reach minimum threshold
2. **LIVE**: Execute strategies, auto-realize on withdrawals
3. **Profit Realization**: Automatic or manual profit extraction
4. **Epoch Transition**: Return to fundraising for next cycle

## 🔧 Core Contracts

### VaultFactory
- Creates vaults using proxy pattern
- Manages vault implementations
- Controls asset whitelisting with guard system
- Handles vault settings and limits

### Vault (ERC-4626)
- Core vault logic with epoch-based lifecycle
- Auto-realization system
- Multi-asset support via guards
- Representative token handling

### AssetHandler
- Chainlink price feed integration
- Asset type classification
- USD price conversion

### Governance
- Guard contract management
- Protocol parameter control
- Strategy authorization

## 📖 Usage Examples

### Deploy System
```bash
npx hardhat run deployment/deploy-vault-system.ts --network sonic
```

### Create Vault
```solidity
// Add supported assets
vaultFactory.addSupportedAsset(USDC, usdcGuard);
vaultFactory.addSupportedAsset(stETH, stethGuard);

// Create new vault
address vault = vaultFactory.createVault(
    "Stratum Yield Vault",
    "SYV", 
    USDC, // underlying asset
    manager,
    maxCapacity
);
```

### Vault Operations
```solidity
// 1. Users deposit during FUNDRAISING
vault.deposit(amount, receiver);

// 2. Manager go live
vault.goLive();

// 3. Execute strategies
vault.callContract(kyberswapRouter, 0, swapData);

// 4. Users withdraw (auto-realization)
vault.withdraw(amount, receiver, owner);
```

## 🧪 Testing

```bash
# Run all tests
npx hardhat test

# 51 tests covering:
# - Auto-realization functionality
# - Fee collection and distribution
# - Business logic protection
# - Guard system integration
# - Vault lifecycle management
```

## 🔒 Security Features

- **Business Logic Protection**: Requires complete liquidation before realization
- **Guard Validation**: All external calls are validated
- **Access Control**: Owner/Manager/Factory permissions
- **Emergency Functions**: Pause/unpause, emergency liquidation
- **Oracle Protection**: Price deviation limits

## 🎛️ Integration

### Custom Asset Guard
```solidity
contract MyAssetGuard is ERC20Guard {
    function getBalance(address vault, address asset) public view override returns (uint256) {
        return ICustomProtocol(asset).getVaultBalance(vault);
    }
    
    function calcValue(address vault, address asset, uint256 balance) external view override returns (uint256) {
        uint256 underlyingAmount = _getUnderlyingAmount(asset, balance);
        return _calculateTokenValue(factory, underlyingAsset, underlyingAmount);
    }
}
```

### Custom Platform Guard
```solidity
contract MyProtocolGuard is IPlatformGuard {
    function txGuard(address vault, address to, bytes memory data) external view override returns (uint16) {
        bytes4 method = bytes4(data[:4]);
        if (method == IMyProtocol.stake.selector) {
            _validateStakeTransaction(vault, data);
            return uint16(TransactionType.Stake);
        }
        revert UnsupportedMethod();
    }
}
```

## 📚 Architecture Benefits

1. **Fee Protection**: Auto-realization prevents fee loss
2. **Fair Distribution**: Consistent treatment for all users
3. **Flexible Asset Support**: Guards handle any asset type
4. **Multi-Layer Security**: Guard validation + business logic protection
5. **Scalability**: Factory pattern for efficient vault creation
6. **Upgradability**: Proxy pattern allows contract upgrades
7. **ERC-4626 Compliance**: Broad compatibility with existing tools

## 📄 License

UNLICENSED - Proprietary software. 
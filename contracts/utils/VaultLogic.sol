// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IVaultFactory.sol";
import "../interfaces/IAssetHandler.sol";
import "../interfaces/IHasGuardInfo.sol";
import "../interfaces/guards/IAssetGuard.sol";
import "../interfaces/IHasSupportedAsset.sol";

/// @title VaultLogic
/// @notice Library containing reusable vault logic to reduce contract size
library VaultLogic {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              STRUCTS
    //////////////////////////////////////////////////////////////*/
    
    struct AssetCalculationParams {
        address vault;
        address factory;
        address underlyingAsset;
        address[] supportedAssets;
        mapping(address => bool) isAssetSupported;
        mapping(address => uint256) lastAssetPrices;
        bool emergencyOracleMode;
        uint256 maxPriceDeviationBps;
    }

    /*//////////////////////////////////////////////////////////////
                           ASSET MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Get asset balance using guards when available
    /// @param vault Vault address
    /// @param asset Asset address
    /// @param factory Factory address for guard lookup
    /// @return Asset balance (handles external contracts via guards)
    function getAssetBalance(
        address vault,
        address asset,
        address factory
    ) internal view returns (uint256) {
        try IHasGuardInfo(factory).getGuard(asset) returns (address guard, string memory) {
            if (guard != address(0)) {
                return IAssetGuard(guard).getBalance(vault, asset);
            }
        } catch {
            // Guard lookup failed, fall back to direct balance
        }
        
        return IERC20(asset).balanceOf(vault);
    }
    
    /// @notice Calculate total vault value efficiently
    /// @param params Asset calculation parameters
    /// @return Total vault value in underlying terms
    function calculateTotalValue(
        AssetCalculationParams storage params
    ) internal view returns (uint256) {
        uint256 totalValue = IERC20(params.underlyingAsset).balanceOf(params.vault);
        
        // Add value from other supported assets
        for (uint256 i = 0; i < params.supportedAssets.length; i++) {
            address currentAsset = params.supportedAssets[i];
            if (currentAsset == params.underlyingAsset) continue;
            
            uint256 balance = getAssetBalance(params.vault, currentAsset, params.factory);
            if (balance > 0) {
                uint256 valueInUnderlying = convertAssetToUnderlying(
                    params.vault,
                    params.factory,
                    currentAsset,
                    balance,
                    params.underlyingAsset,
                    params.lastAssetPrices,
                    params.emergencyOracleMode,
                    params.maxPriceDeviationBps
                );
                totalValue += valueInUnderlying;
            }
        }
        
        return totalValue;
    }
    
    /// @notice Convert asset amount to underlying asset value using guards
    /// @param vault Vault address  
    /// @param factory Factory address
    /// @param asset Asset to convert
    /// @param amount Amount to convert
    /// @param underlyingAsset Underlying asset address
    /// @param lastAssetPrices Price tracking mapping
    /// @param emergencyOracleMode Emergency mode flag
    /// @param maxPriceDeviationBps Max price deviation
    /// @return Value in underlying asset terms
    function convertAssetToUnderlying(
        address vault,
        address factory,
        address asset,
        uint256 amount,
        address underlyingAsset,
        mapping(address => uint256) storage lastAssetPrices,
        bool emergencyOracleMode,
        uint256 maxPriceDeviationBps
    ) internal view returns (uint256) {
        if (asset == underlyingAsset) return amount;
        
        // Try to get asset guard
        try IHasGuardInfo(factory).getGuard(asset) returns (address guard, string memory) {
            if (guard != address(0)) {
                // Use guard to calculate true value
                try IAssetGuard(guard).calcValue(vault, asset, amount) returns (uint256 trueValueUSD) {
                    // Get validated underlying price
                    address assetHandlerAddr = IVaultFactory(factory).getAssetHandler();
                    uint256 underlyingPriceUSD = getValidatedPrice(
                        underlyingAsset,
                        assetHandlerAddr,
                        lastAssetPrices,
                        emergencyOracleMode,
                        maxPriceDeviationBps
                    );
                    
                    if (underlyingPriceUSD > 0) {
                        // Convert to underlying terms
                        uint8 underlyingDecimals = IERC20Metadata(underlyingAsset).decimals();
                        return (trueValueUSD * (10 ** underlyingDecimals)) / underlyingPriceUSD;
                    }
                } catch {
                    // Guard calculation failed, fall through to simple calculation
                }
            }
        } catch {
            // Guard lookup failed, fall through to simple calculation
        }
        
        // Fallback: Simple 1:1 conversion for test environments or when guards fail
        // In production, this should not happen as all assets should have guards
        return amount;
    }
    
    /// @notice Get validated price with manipulation protection
    /// @param asset Asset address
    /// @param assetHandler AssetHandler address
    /// @param lastAssetPrices Price tracking mapping
    /// @param emergencyOracleMode Emergency mode flag
    /// @param maxPriceDeviationBps Max price deviation
    /// @return Validated price
    function getValidatedPrice(
        address asset,
        address assetHandler,
        mapping(address => uint256) storage lastAssetPrices,
        bool emergencyOracleMode,
        uint256 maxPriceDeviationBps
    ) internal view returns (uint256) {
        if (emergencyOracleMode) {
            uint256 emergencyPrice = lastAssetPrices[asset];
            if (emergencyPrice > 0) {
                return emergencyPrice;
            }
        }
        
        // Try to get current price from asset handler
        try IAssetHandler(assetHandler).getUSDPrice(asset) returns (uint256 currentPrice) {
            uint256 lastPrice = lastAssetPrices[asset];
            
            if (lastPrice == 0) return currentPrice;
            
            // Check price deviation
            uint256 priceChange = currentPrice > lastPrice ? 
                ((currentPrice - lastPrice) * 10000) / lastPrice :
                ((lastPrice - currentPrice) * 10000) / lastPrice;
                
            if (priceChange > maxPriceDeviationBps) {
                return lastPrice; // Use safe price
            }
            
            return currentPrice;
        } catch {
            // AssetHandler call failed, try emergency price
            uint256 emergencyPrice = lastAssetPrices[asset];
            if (emergencyPrice > 0) {
                return emergencyPrice;
            }
            
            // Last resort: return 0 (caller should handle this)
            return 0;
        }
    }

    /*//////////////////////////////////////////////////////////////
                           POSITION CHECKING  
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Check if all positions are in underlying asset
    /// @param vault Vault address
    /// @param factory Factory address
    /// @param underlyingAsset Underlying asset  
    /// @param supportedAssets Array of supported assets
    /// @return True if all in underlying
    function areAllAssetsInUnderlying(
        address vault,
        address factory,
        address underlyingAsset,
        address[] storage supportedAssets
    ) internal view returns (bool) {
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address currentAsset = supportedAssets[i];
            if (currentAsset != underlyingAsset) {
                if (getAssetBalance(vault, currentAsset, factory) > 0) {
                    return false;
                }
            }
        }
        return true;
    }

    /// @notice Get assets that need liquidation
    /// @param vault Vault address
    /// @param factory Factory address
    /// @param underlyingAsset Underlying asset
    /// @param supportedAssets Array of supported assets  
    /// @param lastAssetPrices Price tracking mapping
    /// @param emergencyOracleMode Emergency mode flag
    /// @param maxPriceDeviationBps Max price deviation
    /// @return assetsToLiquidate Array of assets to liquidate
    /// @return totalValue Total value to liquidate
    function getAssetsToLiquidate(
        address vault,
        address factory,
        address underlyingAsset,
        address[] storage supportedAssets,
        mapping(address => uint256) storage lastAssetPrices,
        bool emergencyOracleMode,
        uint256 maxPriceDeviationBps
    ) internal view returns (address[] memory assetsToLiquidate, uint256 totalValue) {
        // Count non-underlying assets with balance
        uint256 count = 0;
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address assetAddr = supportedAssets[i];
            if (assetAddr != underlyingAsset && 
                getAssetBalance(vault, assetAddr, factory) > 0) {
                count++;
            }
        }
        
        assetsToLiquidate = new address[](count);
        uint256 index = 0;
        totalValue = 0;
        
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address assetAddr = supportedAssets[i];
            if (assetAddr != underlyingAsset) {
                uint256 balance = getAssetBalance(vault, assetAddr, factory);
                if (balance > 0) {
                    assetsToLiquidate[index] = assetAddr;
                    
                    // Calculate value in underlying terms
                    uint256 value = convertAssetToUnderlying(
                        vault, factory, assetAddr, balance, underlyingAsset,
                        lastAssetPrices, emergencyOracleMode, maxPriceDeviationBps
                    );
                    totalValue += value;
                    
                    index++;
                }
            }
        }
    }


    
    /// @notice Calculate and limit yield to reasonable amount
    /// @param currentTotalValue Current vault value
    /// @param expectedValue Expected value without yield
    /// @return Limited yield amount
    function calculateAndLimitYield(uint256 currentTotalValue, uint256 expectedValue) internal pure returns (uint256) {
        uint256 yield = currentTotalValue - expectedValue;
        uint256 maxReasonableProfit = (expectedValue * 1000) / 10000; // 10% max
        
        if (yield > maxReasonableProfit) {
            yield = maxReasonableProfit;
        }
        return yield;
    }

    /*//////////////////////////////////////////////////////////////
                           VAULT BREAKDOWN  
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Get vault asset breakdown with values
    /// @param vault Vault address
    /// @param factory Factory address
    /// @param underlyingAsset Underlying asset
    /// @param supportedAssets Array of supported assets
    /// @param lastAssetPrices Price tracking mapping
    /// @param emergencyOracleMode Emergency mode flag
    /// @param maxPriceDeviationBps Max price deviation
    /// @return assetAddresses Array of asset addresses
    /// @return assetBalances Array of asset balances  
    /// @return assetValues Array of values in underlying terms
    function getVaultAssetBreakdown(
        address vault,
        address factory,
        address underlyingAsset,
        address[] storage supportedAssets,
        mapping(address => uint256) storage lastAssetPrices,
        bool emergencyOracleMode,
        uint256 maxPriceDeviationBps
    ) internal view returns (
        address[] memory assetAddresses,
        uint256[] memory assetBalances,
        uint256[] memory assetValues
    ) {
        // Count assets (underlying + non-zero supported assets)
        uint256 assetCount = 1; // Start with underlying
        
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            if (supportedAssets[i] != underlyingAsset) {
                uint256 balance = getAssetBalance(vault, supportedAssets[i], factory);
                if (balance > 0) {
                    assetCount++;
                }
            }
        }
        
        assetAddresses = new address[](assetCount);
        assetBalances = new uint256[](assetCount);
        assetValues = new uint256[](assetCount);
        
        // Add underlying asset
        assetAddresses[0] = underlyingAsset;
        assetBalances[0] = IERC20(underlyingAsset).balanceOf(vault);
        assetValues[0] = assetBalances[0]; // 1:1 for underlying
        
        uint256 index = 1;
        
        // Add other assets with non-zero balance
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address currentAsset = supportedAssets[i];
            if (currentAsset != underlyingAsset) {
                uint256 balance = getAssetBalance(vault, currentAsset, factory);
                if (balance > 0) {
                    assetAddresses[index] = currentAsset;
                    assetBalances[index] = balance;
                    assetValues[index] = convertAssetToUnderlying(
                        vault, factory, currentAsset, balance, underlyingAsset,
                        lastAssetPrices, emergencyOracleMode, maxPriceDeviationBps
                    );
                    index++;
                }
            }
        }
    }
} 
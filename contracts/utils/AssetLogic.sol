// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IAssetHandler.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

// Asset validation errors
error InvalidAssetAddress(address asset);
error AssetAlreadySupported(address asset, address vault);
error AssetNotSupported(address asset, address vault);

// Platform validation errors
error InvalidPlatformName(string platform);
error PlatformAlreadySupported(string platform, address vault);
error PlatformNotSupported(string platform, address vault);

// Setting validation errors
error CooldownTooLong(uint256 requested, uint256 maximum);
error DeviationTooHigh(uint256 requested, uint256 maximum);

// Batch operation errors
error EmptyAssetArray();
error AssetArrayTooLarge(uint256 length, uint256 maxLength);

/// @title AssetLogic
/// @notice Library for asset management operations
library AssetLogic {

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event AssetAdded(address indexed vault, address indexed asset, uint256 position);
    event AssetRemoved(address indexed vault, address indexed asset);
    event BatchAssetsAdded(address indexed vault, address[] assets, uint256 totalCount);

    /*//////////////////////////////////////////////////////////////
                           CONSTANTS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Maximum number of assets that can be added in a single batch
    uint256 public constant MAX_BATCH_SIZE = 20;

    /*//////////////////////////////////////////////////////////////
                           ASSET MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Add a supported asset to the vault
    /// @param asset Asset address to add (address(0) allowed for native ETH if properly whitelisted)
    /// @param supportedAssets Array of supported assets
    /// @param assetPosition Mapping of asset positions
    /// @param isAssetSupported Mapping of asset support status
    function addSupportedAsset(
        address asset,
        address[] storage supportedAssets,
        mapping(address => uint256) storage assetPosition,
        mapping(address => bool) storage isAssetSupported
    ) internal {
        // Note: address(0) validation is handled by caller (Vault checks factory whitelist)
        if (isAssetSupported[asset]) revert AssetAlreadySupported(asset, address(this));
        
        supportedAssets.push(asset);
        assetPosition[asset] = supportedAssets.length - 1;
        isAssetSupported[asset] = true;
        
        emit AssetAdded(address(this), asset, supportedAssets.length - 1);
    }

    /// @notice Add multiple supported assets to the vault in a single transaction
    /// @param assets Array of asset addresses to add
    /// @param supportedAssets Array of supported assets
    /// @param assetPosition Mapping of asset positions
    /// @param isAssetSupported Mapping of asset support status
    function batchAddSupportedAssets(
        address[] memory assets,
        address[] storage supportedAssets,
        mapping(address => uint256) storage assetPosition,
        mapping(address => bool) storage isAssetSupported
    ) internal {
        uint256 assetsLength = assets.length;
        
        // Validate batch size
        if (assetsLength == 0) revert EmptyAssetArray();
        if (assetsLength > MAX_BATCH_SIZE) revert AssetArrayTooLarge(assetsLength, MAX_BATCH_SIZE);
        
        // Track successful additions for event
        address[] memory addedAssets = new address[](assetsLength);
        uint256 addedCount = 0;
        
        // Process each asset
        for (uint256 i = 0; i < assetsLength;) {
            address asset = assets[i];
            
            // Skip if already supported (don't revert, just continue)
            if (!isAssetSupported[asset]) {
                // Add asset
                supportedAssets.push(asset);
                assetPosition[asset] = supportedAssets.length - 1;
                isAssetSupported[asset] = true;
                
                // Track for event
                addedAssets[addedCount] = asset;
                addedCount++;
                
                emit AssetAdded(address(this), asset, supportedAssets.length - 1);
            }
            
            unchecked { ++i; }
        }
        
        // Emit batch event if any assets were added
        if (addedCount > 0) {
            // Create properly sized array for event
            address[] memory finalAddedAssets = new address[](addedCount);
            for (uint256 j = 0; j < addedCount;) {
                finalAddedAssets[j] = addedAssets[j];
                unchecked { ++j; }
            }
            
            emit BatchAssetsAdded(address(this), finalAddedAssets, supportedAssets.length);
        }
    }
    
    /// @notice Remove a supported asset from the vault
    /// @param asset Asset address to remove
    /// @param supportedAssets Array of supported assets
    /// @param assetPosition Mapping of asset positions
    /// @param isAssetSupported Mapping of asset support status
    function removeSupportedAsset(
        address asset,
        address[] storage supportedAssets,
        mapping(address => uint256) storage assetPosition,
        mapping(address => bool) storage isAssetSupported
    ) internal {
        if (!isAssetSupported[asset]) revert AssetNotSupported(asset, address(this));
        
        uint256 indexToRemove = assetPosition[asset];
        uint256 lastIndex = supportedAssets.length - 1;
        
        if (indexToRemove != lastIndex) {
            // Move last element to the removed position
            address lastAsset = supportedAssets[lastIndex];
            supportedAssets[indexToRemove] = lastAsset;
            assetPosition[lastAsset] = indexToRemove;
        }
        
        // Remove the last element
        supportedAssets.pop();
        delete assetPosition[asset];
        delete isAssetSupported[asset];
        
        emit AssetRemoved(address(this), asset);
    }

    /*//////////////////////////////////////////////////////////////
                           PLATFORM MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Add a supported platform
    /// @param platform Platform name to add
    /// @param supportedPlatforms Array of supported platforms
    /// @param isPlatformSupported Mapping of platform support status
    function addSupportedPlatform(
        string memory platform,
        string[] storage supportedPlatforms,
        mapping(string => bool) storage isPlatformSupported
    ) internal {
        if (bytes(platform).length == 0) revert InvalidPlatformName(platform);
        if (isPlatformSupported[platform]) revert PlatformAlreadySupported(platform, address(this));
        
        supportedPlatforms.push(platform);
        isPlatformSupported[platform] = true;
    }
    
    /// @notice Remove a supported platform
    /// @param platform Platform name to remove
    /// @param supportedPlatforms Array of supported platforms
    /// @param isPlatformSupported Mapping of platform support status
    function removeSupportedPlatform(
        string memory platform,
        string[] storage supportedPlatforms,
        mapping(string => bool) storage isPlatformSupported
    ) internal {
        if (!isPlatformSupported[platform]) revert PlatformNotSupported(platform, address(this));
        
        // Find and remove from array
        for (uint256 i = 0; i < supportedPlatforms.length; i++) {
            if (keccak256(bytes(supportedPlatforms[i])) == keccak256(bytes(platform))) {
                // Move last element to this position
                supportedPlatforms[i] = supportedPlatforms[supportedPlatforms.length - 1];
                supportedPlatforms.pop();
                break;
            }
        }
        
        isPlatformSupported[platform] = false;
    }

    /*//////////////////////////////////////////////////////////////
                           VALIDATION HELPERS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Check if asset is supported
    /// @param asset Asset address to check
    /// @param isAssetSupported Mapping of asset support status
    /// @return True if asset is supported
    function isSupportedAsset(
        address asset,
        mapping(address => bool) storage isAssetSupported
    ) internal view returns (bool) {
        return isAssetSupported[asset];
    }
    
    /// @notice Check if platform is supported
    /// @param platform Platform name to check
    /// @param isPlatformSupported Mapping of platform support status
    /// @return True if platform is supported
    function isSupportedPlatform(
        string memory platform,
        mapping(string => bool) storage isPlatformSupported
    ) internal view returns (bool) {
        return isPlatformSupported[platform];
    }

    /*//////////////////////////////////////////////////////////////
                           VAULT SETTINGS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Update vault capacity settings
    /// @param newMaxCapacity New maximum capacity
    /// @param newMinDepositAmount New minimum deposit amount
    /// @return Updated max capacity and min deposit amount
    function updateVaultSettings(
        uint256 newMaxCapacity,
        uint256 newMinDepositAmount
    ) internal pure returns (uint256, uint256) {
        return (newMaxCapacity, newMinDepositAmount);
    }
    
    /// @notice Update epoch-related settings
    /// @param newFundraisingDuration New fundraising duration
    /// @param newMinFundraisingAmount New minimum fundraising amount
    /// @return Updated fundraising duration and min amount
    function updateEpochSettings(
        uint256 newFundraisingDuration,
        uint256 newMinFundraisingAmount
    ) internal pure returns (uint256, uint256) {
        return (newFundraisingDuration, newMinFundraisingAmount);
    }

    /*//////////////////////////////////////////////////////////////
                           ORACLE PROTECTION
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Update oracle protection settings
    /// @param newRealizationCooldown New realization cooldown period
    /// @param newMaxPriceDeviationBps New max price deviation
    /// @param MAX_PRICE_DEVIATION Maximum allowed price deviation
    /// @return Updated cooldown and deviation values
    function updateOracleProtection(
        uint256 newRealizationCooldown,
        uint256 newMaxPriceDeviationBps,
        uint256 MAX_PRICE_DEVIATION
    ) internal pure returns (uint256, uint256) {
        if (newRealizationCooldown > 24 hours) revert CooldownTooLong(newRealizationCooldown, 24 hours);
        if (newMaxPriceDeviationBps > MAX_PRICE_DEVIATION) revert DeviationTooHigh(newMaxPriceDeviationBps, MAX_PRICE_DEVIATION);
        
        return (newRealizationCooldown, newMaxPriceDeviationBps);
    }
    
    /// @notice Update asset prices for oracle protection
    /// @param supportedAssets Array of supported assets
    /// @param lastAssetPrices Mapping of last known prices
    /// @param emergencyOracleMode Emergency mode flag
    /// @param assetHandler AssetHandler address for price feeds
    function updateAssetPrices(
        address[] storage supportedAssets,
        mapping(address => uint256) storage lastAssetPrices,
        bool emergencyOracleMode,
        address assetHandler
    ) internal {
        if (emergencyOracleMode) return; // Don't update in emergency mode
        
        // Update prices for all supported assets
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address asset = supportedAssets[i];
            try IAssetHandler(assetHandler).getUSDPrice(asset) returns (uint256 currentPrice) {
                if (currentPrice > 0) {
                    lastAssetPrices[asset] = currentPrice;
                }
            } catch {
                // Price update failed, keep existing price
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                           STRATEGY MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Authorize or deauthorize a strategy
    /// @param strategy Strategy address
    /// @param authorized Authorization status
    /// @param authorizedStrategies Mapping of strategy authorizations
    function setStrategyAuthorization(
        address strategy,
        bool authorized,
        mapping(address => bool) storage authorizedStrategies
    ) internal {
        authorizedStrategies[strategy] = authorized;
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IVaultFactory
/// @notice Interface for VaultFactory contract
interface IVaultFactory {

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event VaultCreated(
        address indexed vault,
        address indexed manager,
        address indexed underlyingAsset,
        string name,
        string symbol,
        uint256 maxCapacity
    );
    
    event AssetWhitelisted(
        address indexed asset,
        uint16 tokenType,
        bool allowed
    );
    
    event GovernanceAddressSet(
        address indexed governanceAddress
    );
    
    event SetAssetHandler(
        address indexed assetHandler
    );
    
    event VaultImplementationUpdated(
        address indexed oldImplementation,
        address indexed newImplementation
    );
    
    event VaultUpgraded(
        address indexed vault,
        address indexed newImplementation
    );
    
    event SetVaultStorageVersion(
        uint256 version
    );
    
    event TreasuryAddressSet(
        address indexed treasuryAddress
    );
    
    event AdminAddressSet(
        address indexed adminAddress
    );
    
    event GovernanceAddressMapped(
        bytes32 indexed name,
        address indexed addr
    );
    
    event UnderlyingAssetAdded(
        address indexed asset,
        uint16 tokenType
    );
    
    event UnderlyingAssetRemoved(
        address indexed asset
    );
    
    event AssetWhitelistedRemoved(
        address indexed asset
    );

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get token type
    /// @param _asset Asset address
    function getTokenType(address _asset) external view returns (uint16);

    /// @notice Get asset type from AssetHandler
    /// @param _asset Asset address
    function getAssetType(address _asset) external view returns (uint16);

    /// @notice Get all deployed vaults
    function getDeployedVaults() external view returns (address[] memory);

    /// @notice Get number of deployed vaults
    function getVaultCount() external view returns (uint256);
    
    /// @notice Get vaults by manager
    /// @param _manager Manager address
    function getVaultsByManager(address _manager) external view returns (address[] memory);
    
    /// @notice Get ERC-4626 vault info
    /// @param _vault Vault address
    function getVaultInfo(address _vault) external view returns (
        address manager,
        address underlyingAsset,
        uint256 totalAssets,
        uint256 totalSupply,
        uint256 maxCapacity,
        bool isPaused,
        uint256 sharePrice
    );

    /// @notice Get detailed vault info using vault's own function
    /// @param _vault Vault address
    function getDetailedVaultInfo(address _vault) external view returns (
        address underlyingAsset,
        uint256 totalShares,
        uint256 totalAssetsAmount,
        uint256 sharePrice,
        uint256 maxCap,
        uint256 minDeposit
    );
    
    /// @notice Get factory stats
    function getFactoryStats() external view returns (
        uint256 totalVaults,
        uint256 totalValueLocked,
        uint256 whitelistedAssetsCount,
        address[] memory topVaultsByTVL
    );
    
    /// @notice Check if address is a vault created by this factory
    /// @param _vault Address to check
    function isValidVault(address _vault) external view returns (bool);

    /// @notice Get vault manager
    /// @param _vault Vault address
    function getVaultManager(address _vault) external view returns (address);

    /// @notice Check if asset is whitelisted
    /// @param _asset Asset address
    function isAssetWhitelisted(address _asset) external view returns (bool);
    
    /// @notice Get implementation version
    function version() external pure returns (string memory);

    /*//////////////////////////////////////////////////////////////
                            EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Emergency asset recovery (only owner)
    /// @param _asset Asset address (0x0 for native token)
    /// @param _amount Amount to recover
    function emergencyRecoverAsset(address _asset, uint256 _amount) external;
    
    /// @notice Set the treasury address
    /// @param _treasuryAddress The address of the treasury contract
    function setTreasuryAddress(address _treasuryAddress) external;
    
    /// @notice Set the admin address
    /// @param _adminAddress The address of the admin
    function setAdminAddress(address _adminAddress) external;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    function proxyAdmin() external view returns (address);
    function vaultImplementation() external view returns (address);
    function implementationVersion() external view returns (uint32);
    function deployedVaults(uint256 index) external view returns (address);
    function isVault(address vault) external view returns (bool);
    function vaultManager(address vault) external view returns (address);
    function vaultIndex(address vault) external view returns (uint256);
    function underlyingAssetAllowed(address asset) external view returns (bool);
    function tokenType(address asset) external view returns (uint16);
    function whitelistedAssets(uint256 index) external view returns (address);
    function assetIndex(address asset) external view returns (uint256);
    function maxCapacityLimit() external view returns (uint256);
    function minCapacityLimit() external view returns (uint256);
    function creationFee() external view returns (uint256);
    function treasury() external view returns (address);
    function admin() external view returns (address);
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function governance() external view returns (address);
    function getAssetHandler() external view returns (address);
    function vaultStorageVersion() external view returns (uint256);
} 
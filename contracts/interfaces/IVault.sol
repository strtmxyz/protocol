// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";

/// @title IVault
/// @notice Interface for Vault contract with epoch-based lifecycle
interface IVault is IERC4626 {
    
    /*//////////////////////////////////////////////////////////////
                            ENUMS & STRUCTS
    //////////////////////////////////////////////////////////////*/
    
    enum VaultState {
        FUNDRAISING,    // Accepting deposits, no strategy execution
        LIVE           // Strategy execution allowed, limited deposits
    }
    
    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposited(
        address indexed vault,
        address indexed user,
        address indexed asset,
        uint256 amount,
        uint256 shares
    );
    
    event Withdrawn(
        address indexed vault,
        address indexed user,
        address indexed asset,
        uint256 amount,
        uint256 shares
    );
    
    event YieldHarvested(
        address indexed vault,
        address indexed asset,
        uint256 amount,
        uint256 managementFee,
        uint256 performanceFee,
        uint256 protocolFee
    );
    
    event ContractCalled(
        address indexed vault,
        address indexed target,
        bytes data,
        uint256 value
    );
    
    event StateChanged(
        uint256 indexed epoch,
        VaultState indexed oldState,
        VaultState indexed newState,
        uint256 timestamp
    );
    
    event EpochAdvanced(
        uint256 indexed oldEpoch,
        uint256 indexed newEpoch,
        uint256 totalAssetsReturned,
        uint256 timestamp
    );

    event OracleProtectionUpdated(
        uint256 harvestCooldown,
        uint256 maxPriceDeviationBps,
        bool emergencyMode
    );
    
    event HarvestBlocked(
        string reason,
        uint256 remainingAssets,
        address[] assetsToLiquidate
    );
    
    event AllPositionsLiquidated(
        uint256 totalConvertedValue,
        uint256 timestamp
    );

    /*//////////////////////////////////////////////////////////////
                            CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Initialize the vault
    function initialize(
        string memory _name,
        string memory _symbol,
        address _underlyingAsset,
        address _manager,
        uint256 _maxCapacity,
        uint256 _managementFee,
        uint256 _performanceFee
    ) external;

    /// @notice Deposit assets to the vault (only during fundraising)
    /// @param _amount Amount to deposit
    /// @return shares Number of shares minted
    function deposit(uint256 _amount) external returns (uint256 shares);
    
    /// @notice Withdraw assets from the vault
    /// @param _shares Number of shares to burn
    /// @return amount Amount of assets withdrawn
    function withdraw(uint256 _shares) external returns (uint256 amount);

    /// @notice Call external contract (only in LIVE state)
    /// @param target Target contract address
    /// @param value ETH value to send
    /// @param data Call data to execute
    function callContract(
        address target,
        uint256 value,
        bytes calldata data
    ) external;
    
    /// @notice Manager manually realizes profits and distributes fees
    function realizeByManager() external;
    
    /// @notice Liquidate all positions for harvest preparation
    function liquidateAllPositionsForHarvest() external;

    /*//////////////////////////////////////////////////////////////
                            EPOCH & STATE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Transition from FUNDRAISING to LIVE state
    function goLive() external;
    
    /// @notice Return to FUNDRAISING state (must liquidate all positions first)
    function returnToFundraising() external;
    
    /// @notice Advance to next epoch (must return to underlying asset first)
    function advanceEpoch() external;
    
    /// @notice Force liquidation of all positions (emergency only)
    function emergencyLiquidateAll() external;

    /*//////////////////////////////////////////////////////////////
                            ASSET MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Add a supported asset
    /// @param _asset Asset to add
    function addSupportedAsset(address _asset) external;
    
    /// @notice Remove a supported asset
    /// @param _asset Asset to remove
    function removeSupportedAsset(address _asset) external;

    /*//////////////////////////////////////////////////////////////
                            MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Update fees
    /// @param _managementFee New management fee
    /// @param _performanceFee New performance fee
    /// @param _withdrawalFee New withdrawal fee
    /// @param _protocolFee New protocol fee share
    function updateFees(
        uint256 _managementFee,
        uint256 _performanceFee,
        uint256 _withdrawalFee,
        uint256 _protocolFee
    ) external;
    
    /// @notice Update vault settings
    /// @param _maxCapacity New max capacity
    /// @param _minDepositAmount New minimum deposit amount
    function updateVaultSettings(
        uint256 _maxCapacity,
        uint256 _minDepositAmount
    ) external;
    
    /// @notice Update epoch settings
    /// @param _fundraisingDuration New fundraising duration
    /// @param _minFundraisingAmount New minimum fundraising amount
    function updateEpochSettings(
        uint256 _fundraisingDuration,
        uint256 _minFundraisingAmount
    ) external;
    
    /// @notice Authorize a strategy
    /// @param _strategy Strategy address
    /// @param _authorized Authorization status
    function setStrategyAuthorization(address _strategy, bool _authorized) external;
    
    /// @notice Update manager
    /// @param _newManager New manager address
    function updateManager(address _newManager) external;
    
    /// @notice Update protocol treasury
    /// @param _newTreasury New protocol treasury address
    function updateProtocolTreasury(address _newTreasury) external;

    /*//////////////////////////////////////////////////////////////
                            EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Emergency pause
    function pause() external;
    
    /// @notice Unpause
    function unpause() external;
    
    /// @notice Emergency asset recovery
    /// @param _asset Asset to recover
    /// @param _amount Amount to recover
    function emergencyRecovery(address _asset, uint256 _amount) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Get number of supported assets
    function getSupportedAssetsCount() external view returns (uint256);
    
    /// @notice Get all supported assets
    function getAllSupportedAssets() external view returns (address[] memory);
    
    /// @notice Get vault info
    function getVaultInfo() external view returns (
        address underlyingAsset,
        uint256 totalShares,
        uint256 totalAssetsAmount,
        uint256 sharePrice,
        uint256 maxCap,
        uint256 minDeposit
    );
    
    /// @notice Get epoch info
    function getEpochInfo() external view returns (
        uint256 epoch,
        VaultState state,
        uint256 startTime,
        uint256 startAssets,
        uint256 endAssets
    );
    
    /// @notice Check if vault can go live
    function canGoLive() external view returns (bool);
    
    /// @notice Check if all positions are liquidated
    function areAllPositionsLiquidated() external view returns (bool);
    
    /// @notice Get assets that need liquidation before harvest
    /// @return assetsToLiquidate Array of asset addresses that need liquidation
    /// @return totalValue Total value of assets to liquidate
    function getAssetsToLiquidate() external view returns (address[] memory assetsToLiquidate, uint256 totalValue);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    function factory() external view returns (address);
    function manager() external view returns (address);
    function underlyingAsset() external view returns (address);
    function protocolTreasury() external view returns (address);
    function currentEpoch() external view returns (uint256);
    function vaultState() external view returns (VaultState);
    function epochStartTime() external view returns (uint256);
    function fundraisingDuration() external view returns (uint256);
    function minFundraisingAmount() external view returns (uint256);
    function managementFee() external view returns (uint256);
    function performanceFee() external view returns (uint256);
    function withdrawalFee() external view returns (uint256);
    function protocolFee() external view returns (uint256);
    function lastHarvestTime() external view returns (uint256);
    function maxCapacity() external view returns (uint256);
    function minDepositAmount() external view returns (uint256);
    function authorizedStrategies(address) external view returns (bool);
    function isAssetSupported(address) external view returns (bool);
    function epochStartAssets(uint256) external view returns (uint256);
    function epochEndAssets(uint256) external view returns (uint256);
    function version() external pure returns (string memory);
    function paused() external view returns (bool);
} 
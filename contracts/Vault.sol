// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IVaultFactory.sol";
import "./interfaces/IAssetHandler.sol";
import "./interfaces/IHasGuardInfo.sol";
import "./interfaces/IHasSupportedAsset.sol";
import "./interfaces/guards/IAssetGuard.sol";
import "./interfaces/guards/IGuard.sol";
import "./interfaces/guards/ITxTrackingGuard.sol";
import "./utils/VaultLogic.sol";
import "./utils/AssetLogic.sol";
import "./utils/FeeLogic.sol";

// Import error definitions from libraries
import {AssetNotSupported, PlatformNotSupported} from "./utils/AssetLogic.sol";
import {ManagementFeeTooHigh, PerformanceFeeTooHigh, IVaultMinter} from "./utils/FeeLogic.sol";

/// @title Strtm (Str.) Vault
/// @notice A vault contract for yield farming and asset management with epoch-based lifecycle
contract Vault is 
    ERC4626Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IVault,
    IHasSupportedAsset,
    IVaultMinter
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/
    
    // Access Control Errors
    error OnlyManager(address caller, address manager);
    error UnauthorizedStrategy(address caller, address manager);
    error Unauthorized(address caller, address required);
    
    // State Management Errors
    error InvalidVaultState(VaultState current, VaultState required);
    error InvalidVaultStateMultiple(VaultState current, VaultState required1, VaultState required2);
    
    // Asset Management Errors
    error InvalidAsset(address asset);
    error InvalidManager(address manager);
    error AssetNotSupportedWithContext(address asset, address factory);
    error PlatformNotSupportedWithContext(string platform);
    error CannotRemoveUnderlyingAsset(address asset);
    
    // Deposit/Withdrawal Errors
    error InsufficientFundsRaised(uint256 currentAmount, uint256 minRequired);
    error DepositsOnlyDuringFundraising(VaultState currentState);
    error BelowMinimumDeposit(uint256 amount, uint256 minAmount);
    error ExceedsCapacity(uint256 requestedTotal, uint256 maxCapacity);
    error InsufficientUnderlyingAssets(uint256 requested, uint256 available);
    
    // Guard and Transaction Errors
    error AssetGuardNotFound(address asset);
    error NoGuardFound(address target);
    error TransactionRejectedByGuard(address guard, address target);
    error ContractCallFailed(address target, bytes data);
    error InvalidTarget(address target);
    
    // Liquidation and Realization Errors
    error MustLiquidateAllPositions(uint256 nonUnderlyingAssets);
    error ManualLiquidationRequired(string reason, uint256 totalValue);
    error RealizationCooldownActive(uint256 timeRemaining);
    
    // Oracle and Price Errors
    error InvalidUnderlyingPriceFeed(address asset, address priceFeed);
    error OnlyInEmergencyMode(bool currentMode);
    error InvalidPrice(uint256 price);
    
    // Internal and Security Errors
    error InternalOnly(address caller);
    error InvalidTreasury(address treasury);
    
    // Fee and Capacity Errors (for better context)
    error InsufficientBalance(uint256 requested, uint256 available);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    // Core vault settings
    address public underlyingAsset;
    address public factory;
    address public manager;
    address public protocolTreasury; // Protocol treasury address for protocol fees
    
    // Epoch and State Management
    uint256 public currentEpoch;
    VaultState public vaultState;
    uint256 public epochStartTime;
    uint256 public fundraisingDuration; // Duration for fundraising phase
    uint256 public minFundraisingAmount; // Minimum amount needed to go live
    

    // New fee structure: Management fee split between protocol (0.5%) and manager (0-2%)
    uint16 public managerFee; // Manager management fee (basis points, 0-200 for 0-2%)
    uint16 public withdrawalFee; // Withdrawal fee (basis points, 0-100 for 0-1%)
    
    // Protocol gets fixed 0.5% management fee (50 basis points)
    uint256 public constant PROTOCOL_MANAGEMENT_FEE = 50; // 0.5%
    // Performance fees: 10% manager + 2.5% protocol = 12.5% total
    uint256 public constant MANAGER_PERFORMANCE_FEE = 1000; // 10%
    uint256 public constant PROTOCOL_PERFORMANCE_FEE = 250; // 2.5%
    
    uint256 public constant MAX_MANAGER_FEE = 200; // 2% max manager fee
    uint256 public constant MAX_WITHDRAWAL_FEE = 100; // 1% max withdrawal fee
    uint256 public constant FEE_DENOMINATOR = 10000;
    
    // Vault metrics
    uint256 internal _totalAssets;
    uint256 public lastRealizationTime;
    uint256 public maxCapacity;
    uint256 public minDepositAmount;
    

    uint256 public realizationCooldown; // Minimum time between profit realizations
    uint16 public maxPriceDeviationBps; // Maximum price change per harvest (basis points) - max 65535 > max 1000
    bool public emergencyOracleMode; // Emergency mode when oracles fail - packed with maxPriceDeviationBps
    uint256 public constant MAX_PRICE_DEVIATION = 1000; // 10% max price change
    mapping(address => uint256) public lastAssetPrices; // Track last known prices
    
    // Auto-realization state for handling multiple withdrawals
    struct RealizationState {
        bool isRealized; // Whether profits have been realized in this period
        uint256 realizedAt; // Timestamp when profits were realized
        uint256 preRealizationValue; // Total value before realization
        uint256 totalFeesExtracted; // Total fees extracted in this realization
        uint256 blockNumber; // Block number when realized
    }
    RealizationState public currentRealization;
    
    // Supported assets for farming
    address[] public supportedAssets;
    mapping(address => uint256) public assetPosition;
    mapping(address => bool) public isAssetSupported;
    
    // Supported platforms for trading
    string[] public supportedPlatforms;
    mapping(string => bool) public isPlatformSupported;
    
    // Strategy execution
    mapping(address => bool) public authorizedStrategies;
    
    // Epoch tracking
    mapping(uint256 => uint256) public epochStartAssets; // Assets at epoch start
    mapping(uint256 => uint256) public epochEndAssets;   // Assets at epoch end

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/
    
    modifier onlyManager() {
        if (msg.sender != manager) revert OnlyManager(msg.sender, manager);
        _;
    }
    
    modifier onlyAuthorizedStrategy() {
        if (!authorizedStrategies[msg.sender] && msg.sender != manager) revert UnauthorizedStrategy(msg.sender, manager);
        _;
    }
    
    modifier onlyInState(VaultState _state) {
        if (vaultState != _state) revert InvalidVaultState(vaultState, _state);
        _;
    }
    
    modifier onlyInStates(VaultState _state1, VaultState _state2) {
        if (vaultState != _state1 && vaultState != _state2) revert InvalidVaultStateMultiple(vaultState, _state1, _state2);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Initialize the vault
    /// @param _name Name of the vault token
    /// @param _symbol Symbol of the vault token
    /// @param _underlyingAsset Main asset of the vault
    /// @param _manager Manager address
    /// @param _maxCapacity Maximum capacity of the vault
    /// @param _managerFee Manager management fee (basis points, 0-200)
    /// @param _withdrawalFee Withdrawal fee (basis points, 0-100)
    function initialize(
        string memory _name,
        string memory _symbol,
        address _underlyingAsset,
        address _manager,
        uint256 _maxCapacity,
        uint256 _managerFee,
        uint256 _withdrawalFee
    ) public initializer {
        _initializeContracts(_name, _symbol, _underlyingAsset);
        _validateInitParams(_underlyingAsset, _manager, _managerFee, _withdrawalFee);
        _setBasicParams(_underlyingAsset, _manager, _maxCapacity);
        _initializeEpochAndState();
        _setCustomFees(_managerFee, _withdrawalFee);
        _setOracleProtectionDefaults();
        _setDefaultAmounts(_underlyingAsset);
        _initializeRealizationState();
        _addSupportedAsset(_underlyingAsset);
        
        // Set factory admin as authorized strategy by default
        address factoryAdmin = IVaultFactory(factory).admin();
        if (factoryAdmin != address(0)) {
            authorizedStrategies[factoryAdmin] = true;
        }
        
        epochStartAssets[currentEpoch] = 0;
    }
    
    /// @notice Initialize inherited contracts
    function _initializeContracts(string memory _name, string memory _symbol, address _underlyingAsset) internal {
        __ERC4626_init(IERC20(_underlyingAsset));
        __ERC20_init(_name, _symbol);
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
    }
    
    /// @notice Validate initialization parameters
    function _validateInitParams(address _underlyingAsset, address _manager, uint256 _managerFee, uint256 _withdrawalFee) internal pure {
        if (_underlyingAsset == address(0)) revert InvalidAsset(_underlyingAsset);
        if (_manager == address(0)) revert InvalidManager(_manager);
        FeeLogic.validateFeeRates(_managerFee, _withdrawalFee);
    }
    
    /// @notice Set basic vault parameters
    function _setBasicParams(address _underlyingAsset, address _manager, uint256 _maxCapacity) internal {
        underlyingAsset = _underlyingAsset;
        manager = _manager;
        maxCapacity = _maxCapacity;
        factory = msg.sender;
        protocolTreasury = IVaultFactory(factory).treasury();
    }
    
    /// @notice Initialize epoch and state
    function _initializeEpochAndState() internal {
        currentEpoch = 1;
        vaultState = VaultState.FUNDRAISING;
        epochStartTime = block.timestamp;
        fundraisingDuration = 30 days;
    }
    
    /// @notice Set custom fee structure for new system
    function _setCustomFees(uint256 _managerFee, uint256 _withdrawalFee) internal {
        managerFee = uint16(_managerFee);
        withdrawalFee = uint16(_withdrawalFee);
    }
    
    /// @notice Set oracle protection defaults
    function _setOracleProtectionDefaults() internal {
        realizationCooldown = 1 hours;
        maxPriceDeviationBps = 500; // 5%
        emergencyOracleMode = false;
    }
    
    /// @notice Set default amounts based on asset decimals
    function _setDefaultAmounts(address _underlyingAsset) internal {
        uint8 decimals = IERC20Metadata(_underlyingAsset).decimals();
        minDepositAmount = 10 * 10**decimals;
        minFundraisingAmount = 1000 * 10**decimals;
        lastRealizationTime = block.timestamp;
    }
    
    /// @notice Initialize auto-realization state
    function _initializeRealizationState() internal {
        currentRealization = RealizationState({
            isRealized: false,
            realizedAt: 0,
            preRealizationValue: 0,
            totalFeesExtracted: 0,
            blockNumber: 0
        });
    }

    /*//////////////////////////////////////////////////////////////
                            EPOCH & STATE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Transition from FUNDRAISING to LIVE state
    function goLive() external onlyManager onlyInState(VaultState.FUNDRAISING) {
        if (totalAssets() < minFundraisingAmount) revert InsufficientFundsRaised(totalAssets(), minFundraisingAmount);
        
        VaultState oldState = vaultState;
        vaultState = VaultState.LIVE;
        epochStartAssets[currentEpoch] = totalAssets();
        
        emit StateChanged(currentEpoch, oldState, vaultState, block.timestamp);
    }
    
    /// @notice Return to FUNDRAISING state (must liquidate all positions first)
    function returnToFundraising() external onlyManager onlyInState(VaultState.LIVE) {
        // Ensure all assets are back to underlying asset
        if (!_areAllAssetsInUnderlying()) revert MustLiquidateAllPositions(supportedAssets.length - 1); // Subtract 1 for underlying
        
        // Auto-realize profits before returning to fundraising to protect fees
        if (_hasUnrealizedProfits()) {
            _performSingleRealization();
        }
        
        VaultState oldState = vaultState;
        vaultState = VaultState.FUNDRAISING;
        
        emit StateChanged(currentEpoch, oldState, vaultState, block.timestamp);
    }
    
    /// @notice Advance to next epoch (must return to underlying asset first)
    function advanceEpoch() external onlyManager onlyInState(VaultState.FUNDRAISING) {
        // Ensure all assets are in underlying asset
        if (!_areAllAssetsInUnderlying()) revert MustLiquidateAllPositions(supportedAssets.length - 1); // Subtract 1 for underlying
        
        uint256 oldEpoch = currentEpoch;
        uint256 currentTotalAssets = totalAssets();
        epochEndAssets[oldEpoch] = currentTotalAssets;
        
        currentEpoch++;
        epochStartTime = block.timestamp;
        epochStartAssets[currentEpoch] = currentTotalAssets;
        
        emit EpochAdvanced(oldEpoch, currentEpoch, currentTotalAssets, block.timestamp);
    }
    

    
    // Emergency liquidation function removed for security reasons

    /*//////////////////////////////////////////////////////////////
                          ASSET GUARD FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Get accurate balance of an asset using guards
    /// @param asset Asset address
    /// @return Balance of the asset (handles external contracts via guards)
    function assetBalance(address asset) public view returns (uint256) {
        return VaultLogic.getAssetBalance(address(this), asset, factory);
    }

    /*//////////////////////////////////////////////////////////////
                          OPTIMIZED WRAPPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Cached wrapper for checking if all assets are in underlying
    /// @dev Optimized version with parameter caching to avoid repeated calls
    /// @return True if all assets are in underlying asset
    function _areAllAssetsInUnderlying() internal view returns (bool) {
        return VaultLogic.areAllAssetsInUnderlying(
            address(this),
            factory,
            asset(),
            supportedAssets
        );
    }

    /// @notice Cached wrapper for getting assets to liquidate
    /// @dev Optimized version with parameter caching for frequent calls
    /// @return assetsToLiquidate Array of assets to liquidate
    /// @return totalValue Total value of assets to liquidate
    function _getAssetsToLiquidate() internal view returns (address[] memory assetsToLiquidate, uint256 totalValue) {
        return VaultLogic.getAssetsToLiquidate(
            address(this),
            factory,
            asset(),
            supportedAssets,
            lastAssetPrices,
            emergencyOracleMode,
            maxPriceDeviationBps
        );
    }

    /// @notice Optimized wrapper for asset balance with validation
    /// @param assetAddress Asset to check balance for
    /// @return balance Asset balance
    function _getAssetBalance(address assetAddress) internal view returns (uint256) {
        return VaultLogic.getAssetBalance(address(this), assetAddress, factory);
    }

    /// @notice Optimized wrapper for minting shares for fees
    /// @param managerFeeValue Manager fee value
    /// @param protocolFeeValue Protocol fee value
    /// @param sharePrice Current share price
    function _mintSharesForFees(
        uint256 managerFeeValue,
        uint256 protocolFeeValue,
        uint256 sharePrice
    ) internal {
        // Validation before minting
        if (managerFeeValue == 0 && protocolFeeValue == 0) return;
        
        FeeLogic.mintSharesForFees(
            address(this),
            manager,
            protocolTreasury,
            managerFeeValue,
            protocolFeeValue,
            sharePrice
        );
    }

    /// @notice Optimized wrapper for asset value conversion with caching
    /// @param assetAddress Asset to convert
    /// @param amount Amount to convert
    /// @return Value in underlying asset terms
    function _convertAssetToUnderlying(address assetAddress, uint256 amount) internal view returns (uint256) {
        return VaultLogic.convertAssetToUnderlying(
            address(this),
            factory,
            assetAddress,
            amount,
            asset(),
            lastAssetPrices,
            emergencyOracleMode,
            maxPriceDeviationBps
        );
    }

    /// @notice Batch wrapper for checking supported assets and platforms
    /// @param target Target address
    /// @param platform Platform name
    /// @return assetSupported Whether asset is supported
    /// @return platformSupported Whether platform is supported
    function _checkSupportedAssetAndPlatform(
        address target,
        string memory platform
    ) internal view returns (bool assetSupported, bool platformSupported) {
        assetSupported = AssetLogic.isSupportedAsset(target, isAssetSupported);
        platformSupported = AssetLogic.isSupportedPlatform(platform, isPlatformSupported);
    }

    /*//////////////////////////////////////////////////////////////
                          PARAMETER CACHING HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get cached vault parameters for repeated operations
    /// @return vaultAddress This vault's address
    /// @return factoryAddress Factory address
    /// @return underlyingAssetAddress Underlying asset address
    /// @return assetsArray Supported assets array
    function _getCachedVaultParams() internal view returns (
        address vaultAddress,
        address factoryAddress,
        address underlyingAssetAddress,
        address[] memory assetsArray
    ) {
        vaultAddress = address(this);
        factoryAddress = factory;
        underlyingAssetAddress = asset();
        assetsArray = supportedAssets;
    }

    /// @notice Get cached oracle parameters for price operations
    /// @return prices Last asset prices mapping
    /// @return emergencyMode Emergency oracle mode flag
    /// @return maxDeviation Maximum price deviation
    function _getCachedOracleParams() internal view returns (
        mapping(address => uint256) storage prices,
        bool emergencyMode,
        uint256 maxDeviation
    ) {
        prices = lastAssetPrices;
        emergencyMode = emergencyOracleMode;
        maxDeviation = maxPriceDeviationBps;
    }

    /// @notice Get cached fee parameters for fee calculations
    /// @return managerFeeRate Manager fee rate
    /// @return withdrawalFeeRate Withdrawal fee rate
    /// @return protocolMgmtFee Protocol management fee constant
    /// @return managerPerfFee Manager performance fee constant
    /// @return protocolPerfFee Protocol performance fee constant
    /// @return feeDenominator Fee denominator constant
    function _getCachedFeeParams() internal view returns (
        uint256 managerFeeRate,
        uint256 withdrawalFeeRate,
        uint256 protocolMgmtFee,
        uint256 managerPerfFee,
        uint256 protocolPerfFee,
        uint256 feeDenominator
    ) {
        managerFeeRate = managerFee;
        withdrawalFeeRate = withdrawalFee;
        protocolMgmtFee = PROTOCOL_MANAGEMENT_FEE;
        managerPerfFee = MANAGER_PERFORMANCE_FEE;
        protocolPerfFee = PROTOCOL_PERFORMANCE_FEE;
        feeDenominator = FEE_DENOMINATOR;
    }

    /// @notice Optimized batch operation for checking vault state
    /// @return allInUnderlying Whether all assets are in underlying
    /// @return hasUnrealizedProfits Whether there are unrealized profits
    /// @return inLiveState Whether vault is in LIVE state
    function _getVaultStatusBatch() internal view returns (
        bool allInUnderlying,
        bool hasUnrealizedProfits,
        bool inLiveState
    ) {
        allInUnderlying = _areAllAssetsInUnderlying();
        hasUnrealizedProfits = _hasUnrealizedProfits();
        inLiveState = (vaultState == VaultState.LIVE);
    }

    /*//////////////////////////////////////////////////////////////
                        ERROR HANDLING HELPERS
    //////////////////////////////////////////////////////////////*/



    /// @notice Safe wrapper for guard calls with better error context
    /// @param guard Guard address
    /// @param target Target contract
    /// @param data Transaction data
    /// @param value ETH value
    /// @return txType Transaction type returned by guard
    function _callGuardWithContext(address guard, address target, bytes calldata data, uint256 value) internal returns (uint16 txType) {
        try IGuard(guard).txGuard(address(this), target, data, value) returns (uint16 returnedTxType) {
            return returnedTxType;
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Guard validation failed: ", reason)));
        } catch (bytes memory lowLevelData) {
            // Handle custom errors or provide context
            revert TransactionRejectedByGuard(guard, target);
        }
    }

    /// @notice Safe wrapper for external contract calls with better error context
    /// @param target Target contract
    /// @param data Call data
    /// @param value ETH value
    /// @return success Whether call succeeded
    /// @return returnData Return data from call
    function _callExternalWithContext(address target, bytes calldata data, uint256 value) internal returns (bool success, bytes memory returnData) {
        (success, returnData) = target.call{value: value}(data);
        if (!success) {
            // Try to decode revert reason
            if (returnData.length > 0) {
                // Try to decode string revert reason
                try this.decodeRevertReason(returnData) returns (string memory reason) {
                    revert(string(abi.encodePacked("External call failed: ", reason)));
                } catch {
                    // If decode fails, use generic error with context
                    revert ContractCallFailed(target, data);
                }
            } else {
                // No return data, use generic error
                revert ContractCallFailed(target, data);
            }
        }
    }

    /// @notice Decode revert reason from return data
    /// @param returnData Return data from failed call
    /// @return reason Decoded revert reason
    function decodeRevertReason(bytes calldata returnData) external pure returns (string memory reason) {
        // Check if it's a string revert (Error(string))
        if (returnData.length >= 68 && bytes4(returnData[:4]) == 0x08c379a0) {
            // Decode the string from the Error(string) selector
            return abi.decode(returnData[4:], (string));
        }
        return "Unknown error";
    }

    /*//////////////////////////////////////////////////////////////
                            ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Total amount of underlying assets held by the vault
    function totalAssets() public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        return _calculateTotalValue();
    }
    
    /// @notice Calculate total vault value in underlying asset terms (gas optimized)
    function _calculateTotalValue() internal view returns (uint256) {
    
        address cachedUnderlyingAsset = asset();
        uint256 underlyingBalance = IERC20(cachedUnderlyingAsset).balanceOf(address(this));
        
        // Early return if no other assets to process
        uint256 assetsLength = supportedAssets.length;
        if (assetsLength <= 1) return underlyingBalance;
        
        uint256 totalValue = underlyingBalance;
        

        address cachedFactory = factory;
        address assetHandlerAddr = IVaultFactory(cachedFactory).getAssetHandler();
        uint256 underlyingPriceUSD = VaultLogic.getValidatedPrice(cachedUnderlyingAsset, assetHandlerAddr, lastAssetPrices, emergencyOracleMode, maxPriceDeviationBps);
        uint8 underlyingDecimals = IERC20Metadata(cachedUnderlyingAsset).decimals();
        
        // Early return if invalid underlying price
        if (underlyingPriceUSD <= 0) return underlyingBalance;
        

        for (uint256 i = 0; i < assetsLength;) {
            address currentAsset = supportedAssets[i];
            
            // Skip underlying asset (already counted)
            if (currentAsset != cachedUnderlyingAsset) {
                uint256 balance = _getAssetBalance(currentAsset);
                
    
                if (balance > 0) {
                    uint256 valueInUnderlying = _convertAssetToUnderlyingOptimized(
                        currentAsset, 
                        balance, 
                        cachedFactory, 
                        assetHandlerAddr, 
                        underlyingPriceUSD, 
                        underlyingDecimals
                    );
                    totalValue += valueInUnderlying;
                }
            }
            
            unchecked { ++i; }
        }
        
        return totalValue;
    }
    
    /// @notice Convert asset amount to underlying asset value using guards (optimized version for loops)
    /// @param assetAddress The asset to convert
    /// @param amount Amount of the asset
    /// @param cachedFactory Cached factory address
    /// @param assetHandlerAddr Cached asset handler address  
    /// @param underlyingPriceUSD Cached underlying price
    /// @param underlyingDecimals Cached underlying decimals
    /// @return Value in underlying asset terms
    function _convertAssetToUnderlyingOptimized(
        address assetAddress, 
        uint256 amount,
        address cachedFactory,
        address assetHandlerAddr,
        uint256 underlyingPriceUSD,
        uint8 underlyingDecimals
    ) internal view returns (uint256) {

        (address guard, ) = IHasGuardInfo(cachedFactory).getGuard(assetAddress);
        if (guard == address(0)) return 0;
        
        // Use guard to calculate the accurate value
        try IAssetGuard(guard).calcValue(address(this), assetAddress, amount) returns (uint256 trueValueUSD) {
    
            return (trueValueUSD * (10 ** underlyingDecimals)) / underlyingPriceUSD;
        } catch {
            return 0;
        }
    }


    

    


    /// @notice Maximum deposit limit
    function maxDeposit(address) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        if (paused()) return 0;
        
        // No deposits allowed in LIVE state except for yield/rewards
        if (vaultState == VaultState.LIVE) return 0;
        
        uint256 currentTotalAssets = totalAssets();
        return maxCapacity > currentTotalAssets ? maxCapacity - currentTotalAssets : 0;
    }

    /// @notice Maximum withdrawal limit
    function maxWithdraw(address owner) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        if (paused()) return 0;
        
        // Limited withdrawals in LIVE state
        if (vaultState == VaultState.LIVE) {
            // Only allow withdrawal of underlying asset portion
            uint256 underlyingBalance = IERC20(asset()).balanceOf(address(this));
            uint256 userShares = balanceOf(owner);
            uint256 totalShares = totalSupply();
            
            if (totalShares == 0) return 0;
            
            uint256 userUnderlyingPortion = (underlyingBalance * userShares) / totalShares;
            return userUnderlyingPortion;
        }
        
        return convertToAssets(balanceOf(owner));
    }

    /// @notice Preview deposit with fees
    function previewDeposit(uint256 assets) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        if (vaultState != VaultState.FUNDRAISING) revert DepositsOnlyDuringFundraising(vaultState);
        if (assets < minDepositAmount) revert BelowMinimumDeposit(assets, minDepositAmount);
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /// @notice Preview withdrawal with fees
    function previewWithdraw(uint256 assets) public view override(ERC4626Upgradeable, IERC4626) returns (uint256) {
        // Fix: Calculate shares based on assets amount only, not assets + fee
        // The fee will be deducted from the user's received amount, not from share calculation
        return _convertToShares(assets, Math.Rounding.Ceil);
    }

    /// @notice Deposit assets and receive shares (only during fundraising)
    function deposit(uint256 assets, address receiver) public override(ERC4626Upgradeable, IERC4626) whenNotPaused onlyInState(VaultState.FUNDRAISING) returns (uint256) {
        if (assets < minDepositAmount) revert BelowMinimumDeposit(assets, minDepositAmount);
        if (totalAssets() + assets > maxCapacity) revert ExceedsCapacity(totalAssets() + assets, maxCapacity);
        
        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        
        return shares;
    }

    /// @notice Smart auto-realization for multiple withdrawals
    /// @dev Realizes profits once per period, caches result for subsequent withdrawals
    function _smartAutoRealize() internal {
        // Skip if not in LIVE state or already realized in this period
        if (vaultState != VaultState.LIVE) return;
        
        // Reset realization state if cooldown period has passed
        if (currentRealization.isRealized && 
            block.timestamp >= currentRealization.realizedAt + realizationCooldown) {
            currentRealization.isRealized = false;
        }
        
        // Skip if already realized in current period
        if (currentRealization.isRealized) return;
        
        // Check if we have unrealized profits
        if (!_areAllAssetsInUnderlying()) return;
        if (!_hasUnrealizedProfits()) return;
        
        // Perform one-time realization for this period
        uint256 preRealizationValue = totalAssets();
        _performSingleRealization();
        
        // Cache realization state
        uint256 feesExtracted = preRealizationValue - totalAssets();
        currentRealization = RealizationState({
            isRealized: true,
            realizedAt: block.timestamp,
            preRealizationValue: preRealizationValue,
            totalFeesExtracted: feesExtracted,
            blockNumber: block.number
        });
        
        emit AutoRealizationTriggered(msg.sender, preRealizationValue, feesExtracted, block.number);
    }
    
    /// @notice Check if vault has unrealized profits
    function _hasUnrealizedProfits() internal view returns (bool) {
        uint256 currentTotalValue = totalAssets();
        uint256 expectedValue = _getExpectedVaultValue();
        return currentTotalValue > expectedValue;
    }
    
    /// @notice Perform single profit realization (internal) with mint shares
    function _performSingleRealization() internal {
        // Skip oracle and cooldown checks for auto-realization
        uint256 currentTotalValue = totalAssets();
        uint256 expectedValue = _getExpectedVaultValue();
        
        if (currentTotalValue <= expectedValue) return;
        
        uint256 yield = currentTotalValue - expectedValue;
        
        // Profit sanity check
        uint256 maxReasonableProfit = (expectedValue * 1000) / 10000; // 10% max
        if (yield > maxReasonableProfit) {
            yield = maxReasonableProfit;
        }
        
        // Calculate fees using new structure
        (uint256 protocolManagementFee, uint256 managerManagementFee, uint256 managerPerformanceFee, uint256 protocolPerformanceFee) = _calculateAllFees(yield, expectedValue);
        
        // Mint shares for fees instead of extracting underlying
        uint256 currentSharePrice = totalSupply() > 0 ? (totalAssets() * 1e18) / totalSupply() : 1e18;
        uint256 totalManagerFeeValue = managerManagementFee + managerPerformanceFee;
        uint256 totalProtocolFeeValue = protocolManagementFee + protocolPerformanceFee;
        
        _mintSharesForFees(
            totalManagerFeeValue,
            totalProtocolFeeValue,
            currentSharePrice
        );
        
        // Update timestamp
        lastRealizationTime = block.timestamp;
        
        uint256 totalManagementFee = protocolManagementFee + managerManagementFee;
        uint256 totalPerformanceFee = managerPerformanceFee + protocolPerformanceFee;
        emit YieldHarvested(address(this), asset(), yield, totalManagementFee, totalPerformanceFee, protocolPerformanceFee);
    }

    /// @notice Withdraw assets by burning shares
    function withdraw(uint256 assets, address receiver, address owner) public override(ERC4626Upgradeable, IERC4626) whenNotPaused onlyInStates(VaultState.FUNDRAISING, VaultState.LIVE) returns (uint256) {
        // Smart auto-realize profits before withdrawal in LIVE state
        if (vaultState == VaultState.LIVE) {
            _smartAutoRealize();
            
            uint256 maxWithdrawable = maxWithdraw(owner);
            if (assets > maxWithdrawable) revert InsufficientUnderlyingAssets(assets, maxWithdrawable);
        }
        
        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);
        
        return shares;
    }

    /// @notice Internal deposit function
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        IERC20(asset()).safeTransferFrom(caller, address(this), assets);
        _mint(receiver, shares);
        
        emit Deposit(caller, receiver, assets, shares);
    }
    


    /// @notice Internal withdraw function
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        
        // Calculate basic withdrawal fee
        uint256 fee = FeeLogic.calculateWithdrawalFee(assets, withdrawalFee, FEE_DENOMINATOR);
        uint256 assetsAfterFee = assets - fee;
        
        _burn(owner, shares);
        
        IERC20(asset()).safeTransfer(receiver, assetsAfterFee);
        
        // Transfer fee to manager
        if (fee > 0) {
            IERC20(asset()).safeTransfer(manager, fee);
        }
        
        emit Withdraw(caller, receiver, owner, assets, shares);
    }
    


    /*//////////////////////////////////////////////////////////////
                            STRATEGY FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Call external contract (only in LIVE state)
    /// @param target Target contract address
    /// @param value ETH value to send
    /// @param data Call data to execute
    function callContract(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyAuthorizedStrategy onlyInState(VaultState.LIVE) whenNotPaused {
        if (target == address(0)) revert InvalidTarget(target);
        
        // Get guard for this target contract
        (address guard, string memory platform) = IHasGuardInfo(factory).getGuard(target);
        if (guard == address(0)) revert NoGuardFound(target);
        
        // Determine if this is a platform or asset guard
        bool isPlatform = bytes(platform).length > 0;
        
        if (isPlatform) {
            // Platform guard - check if platform is supported
            if (!AssetLogic.isSupportedPlatform(platform, isPlatformSupported)) revert PlatformNotSupportedWithContext(platform);
        } else {
            // Asset guard - check if asset is supported
            if (!AssetLogic.isSupportedAsset(target, isAssetSupported)) revert AssetNotSupportedWithContext(target, factory);
        }
        
        // Execute guard validation
        uint16 txType;
        if (value > 0) {
            txType = _callGuardWithContext(guard, target, data, value);
        } else {
            txType = _callGuardWithContext(guard, target, data, 0);
        }
        if (txType == 0) revert TransactionRejectedByGuard(guard, target);
        
        // Execute the call
        (bool success, bytes memory resultData) = _callExternalWithContext(target, data, value);
        
        // Check for post-transaction guard callback
        (bool hasFunction, bytes memory returnData) = guard.call(
            abi.encodeWithSignature("isTxTrackingGuard()")
        );
        if (hasFunction && abi.decode(returnData, (bool))) {
            ITxTrackingGuard(guard).afterTxGuard(address(this), target, data, resultData);
        }
        
        emit ContractCalled(address(this), target, data, value);
    }

    /*//////////////////////////////////////////////////////////////
                            YIELD MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    // YIELD MANAGEMENT DESIGN:
    // 1. Auto-Realization: Profits are automatically realized when users withdraw (if conditions met)
    // 2. Single Realization: Only one realization per cooldown period to handle multiple withdrawals
    // 3. State Caching: Realization state is cached to ensure consistent behavior for all users
    // 4. Manager Override: Manager can still manually realize via realizeByManager()
    // 5. Fee Protection: Ensures fees are always collected before users can withdraw profits
    
    /// @notice Manager manually realizes profits and distributes fees
    /// @dev Business Logic Protection: ALL non-underlying positions must be liquidated first
    function realizeByManager() external onlyManager {
        if (_checkRecentAutoRealization()) return;
        
        _enforceCompleteLiquidation();
        _validateRealizationTiming();
        _updateAssetPrices();
        
        (uint256 currentTotalValue, uint256 expectedValue) = _getVaultValuation();
        
        if (currentTotalValue <= expectedValue) {
            _updateRealizationWithoutGains();
            return;
        }
        
        uint256 yield = VaultLogic.calculateAndLimitYield(currentTotalValue, expectedValue);
        (uint256 protocolManagementFee, uint256 managerManagementFee, uint256 managerPerformanceFee, uint256 protocolPerformanceFee) = _calculateAllFees(yield, expectedValue);
        
        // Mint shares for fees
        uint256 currentSharePrice = totalSupply() > 0 ? (totalAssets() * 1e18) / totalSupply() : 1e18;
        uint256 totalManagerFeeValue = managerManagementFee + managerPerformanceFee;
        uint256 totalProtocolFeeValue = protocolManagementFee + protocolPerformanceFee;
        
        _mintSharesForFees(
            totalManagerFeeValue,
            totalProtocolFeeValue,
            currentSharePrice
        );
        _finalizeRealization();
        
        uint256 totalManagementFee = protocolManagementFee + managerManagementFee;
        uint256 totalPerformanceFee = managerPerformanceFee + protocolPerformanceFee;
        emit YieldHarvested(address(this), asset(), yield, totalManagementFee, totalPerformanceFee, protocolPerformanceFee);
    }
    
    /// @notice Check if recent auto-realization prevents new realization
    /// @return True if should skip realization
    function _checkRecentAutoRealization() internal returns (bool) {
        if (currentRealization.isRealized && 
            block.timestamp < currentRealization.realizedAt + realizationCooldown) {
            lastRealizationTime = block.timestamp;
            return true;
        }
        return false;
    }
    
    /// @notice Validate timing requirements for realization
    function _validateRealizationTiming() internal view {
        if (block.timestamp < lastRealizationTime + realizationCooldown) revert RealizationCooldownActive(lastRealizationTime + realizationCooldown - block.timestamp);
    }
    
    /// @notice Get current and expected vault valuations
    /// @return currentTotalValue Current vault value
    /// @return expectedValue Expected value without yield
    function _getVaultValuation() internal view returns (uint256 currentTotalValue, uint256 expectedValue) {
        currentTotalValue = totalAssets();
        expectedValue = _getExpectedVaultValue();
    }
    
    /// @notice Update realization when no gains are found
    function _updateRealizationWithoutGains() internal {
        lastRealizationTime = block.timestamp;
        currentRealization.isRealized = false;
    }

    
    /// @notice Calculate all fee components for new structure
    /// @param yield Realized yield amount
    /// @param expectedValue Expected vault value
    /// @return protocolManagementFee Protocol's management fee
    /// @return managerManagementFee Manager's management fee
    /// @return managerPerformanceFee Manager's performance fee
    /// @return protocolPerformanceFee Protocol's performance fee
    function _calculateAllFees(uint256 yield, uint256 expectedValue) internal view returns (
        uint256 protocolManagementFee,
        uint256 managerManagementFee,
        uint256 managerPerformanceFee, 
        uint256 protocolPerformanceFee
    ) {
        uint256 timeElapsed = block.timestamp - lastRealizationTime;
        (protocolManagementFee, managerManagementFee) = FeeLogic.calculateManagementFees(
            expectedValue, PROTOCOL_MANAGEMENT_FEE, managerFee, timeElapsed, FEE_DENOMINATOR
        );
        
        (managerPerformanceFee, protocolPerformanceFee) = FeeLogic.calculatePerformanceFees(
            yield, MANAGER_PERFORMANCE_FEE, PROTOCOL_PERFORMANCE_FEE, FEE_DENOMINATOR
        );
    }
    
    /// @notice Finalize realization state
    function _finalizeRealization() internal {
        lastRealizationTime = block.timestamp;
        currentRealization.isRealized = false;
    }
    
    /// @notice Enforce complete liquidation requirement for yield harvesting
    /// @dev Ensures ALL non-underlying positions are liquidated before harvest
    function _enforceCompleteLiquidation() internal {
        if (!_areAllAssetsInUnderlying()) {
            // Get assets that need to be liquidated
            (address[] memory assetsToLiquidate, uint256 totalNonUnderlyingValue) = _getAssetsToLiquidate();
            
            emit HarvestBlocked(
                "Manual liquidation required: Use callContract() to liquidate positions before harvest",
                totalNonUnderlyingValue,
                assetsToLiquidate
            );
            
            revert ManualLiquidationRequired("Must liquidate all non-underlying positions", totalNonUnderlyingValue);
        }
    }
    
    /// @notice Check and verify all positions are liquidated for harvest
    /// @dev Manager must manually liquidate positions via callContract() before calling this
    function liquidateAllPositionsForHarvest() external onlyManager {
        // Get positions that need liquidation
        (address[] memory assetsToLiquidate, uint256 totalValue) = _getAssetsToLiquidate();
        
        if (assetsToLiquidate.length > 0) {
            // Still have positions to liquidate - provide guidance
            revert ManualLiquidationRequired("Still have non-underlying positions to liquidate", totalValue);
        }
        
        // All positions are liquidated
        emit AllPositionsLiquidated(totalValue, block.timestamp);
    }
    

    
    /// @notice Get expected vault value without yield (baseline)
    /// @dev Uses last recorded value plus any deposits since last harvest
    function _getExpectedVaultValue() internal view returns (uint256) {
        // Use epoch start assets as baseline
        uint256 epochStartValue = epochStartAssets[currentEpoch];
        
        // If no epoch data, fall back to share-based calculation
        if (epochStartValue == 0) {
            // Conservative estimate: assume 1:1 share to asset ratio as baseline
            return totalSupply(); // This represents initial deposits without yield
        }
        
        return epochStartValue;
    }
    
    /// @notice Mint shares for fees (implements IVaultMinter interface)
    /// @param to Address to mint shares to
    /// @param shares Number of shares to mint
    function mint(address to, uint256 shares) external override {
        // Allow calls from within _mintSharesForFees context
        // This is safe because _mintSharesForFees is only called from internal fee logic
        _mint(to, shares);
    }
    
    /// @notice Get current share price (implements IVaultMinter interface)
    /// @param assets Assets amount
    /// @return shares Equivalent shares
    function convertToShares(uint256 assets) public view override(ERC4626Upgradeable, IERC4626, IVaultMinter) returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }


    /// @notice Update stored asset prices for oracle protection
    function _updateAssetPrices() internal {
        if (emergencyOracleMode) return; // Don't update prices in emergency mode
        
        try this._updateAssetPricesExternal() {
            // Price update successful
        } catch {
            // If price update fails, enter emergency mode
            emergencyOracleMode = true;
            emit EmergencyOracleModeActivated();
        }
    }
    
    /// @notice External function for updating asset prices (for try-catch)
    function _updateAssetPricesExternal() external {
        if (msg.sender != address(this)) revert InternalOnly(msg.sender);
        
        address assetHandlerAddr = IVaultFactory(factory).getAssetHandler();
        
        // Update underlying asset price
        uint256 underlyingPrice = IAssetHandler(assetHandlerAddr).getUSDPrice(asset());
        lastAssetPrices[asset()] = underlyingPrice;
        
        // Update all supported asset prices
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            if (supportedAssets[i] != asset()) {
                uint256 assetPrice = IAssetHandler(assetHandlerAddr).getUSDPrice(supportedAssets[i]);
                lastAssetPrices[supportedAssets[i]] = assetPrice;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ASSET MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Add a supported asset (with factory whitelist validation)
    /// @param _asset Asset to add
    function addSupportedAsset(address _asset) external onlyManager {
        _addSupportedAsset(_asset);
    }

    /// @notice Add multiple supported assets in a single transaction (with factory whitelist validation)
    /// @param _assets Array of assets to add
    function batchAddSupportedAssets(address[] calldata _assets) external onlyManager {
        _batchAddSupportedAssets(_assets);
    }
    
    /// @notice Remove a supported asset
    /// @param _asset Asset to remove
    function removeSupportedAsset(address _asset) external onlyManager {
        if (_asset == asset()) revert CannotRemoveUnderlyingAsset(asset());
        
        AssetLogic.removeSupportedAsset(
            _asset,
            supportedAssets,
            assetPosition,
            isAssetSupported
        );
    }
    
    /// @notice Internal function to add supported asset with factory whitelist validation
    /// @param _asset Asset to add
    function _addSupportedAsset(address _asset) internal {
        // 🛡️ SECURITY: Check factory whitelist before allowing asset
        if (!IVaultFactory(factory).isAssetWhitelisted(_asset)) {
            revert AssetNotSupportedWithContext(_asset, factory); // Asset not whitelisted by factory
        }
        
        AssetLogic.addSupportedAsset(
            _asset,
            supportedAssets,
            assetPosition,
            isAssetSupported
        );
    }

    /// @notice Internal function to batch add supported assets with factory whitelist validation
    /// @param _assets Array of assets to add
    function _batchAddSupportedAssets(address[] calldata _assets) internal {
        // Pre-validate all assets against factory whitelist
        uint256 assetsLength = _assets.length;
        
        // Create array for validated assets
        address[] memory validatedAssets = new address[](assetsLength);
        uint256 validatedCount = 0;
        
        // Validate each asset against factory whitelist
        for (uint256 i = 0; i < assetsLength;) {
            address asset = _assets[i];
            
            // 🛡️ SECURITY: Check factory whitelist before allowing asset
            if (IVaultFactory(factory).isAssetWhitelisted(asset)) {
                validatedAssets[validatedCount] = asset;
                validatedCount++;
            }
            // Note: Silently skip non-whitelisted assets instead of reverting
            // This allows partial success in batch operations
            
            unchecked { ++i; }
        }
        
        // Create properly sized array with only validated assets
        if (validatedCount > 0) {
            address[] memory finalAssets = new address[](validatedCount);
            for (uint256 j = 0; j < validatedCount;) {
                finalAssets[j] = validatedAssets[j];
                unchecked { ++j; }
            }
            
            // Call AssetLogic batch function with validated assets
            AssetLogic.batchAddSupportedAssets(
                finalAssets,
                supportedAssets,
                assetPosition,
                isAssetSupported
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                            PLATFORM MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Add a supported platform
    /// @param _platform Platform name to add
    function addSupportedPlatform(string memory _platform) external onlyManager {
        AssetLogic.addSupportedPlatform(
            _platform,
            supportedPlatforms,
            isPlatformSupported
        );
    }
    
    /// @notice Remove a supported platform
    /// @param _platform Platform name to remove
    function removeSupportedPlatform(string memory _platform) external onlyManager {
        AssetLogic.removeSupportedPlatform(
            _platform,
            supportedPlatforms,
            isPlatformSupported
        );
    }

    /*//////////////////////////////////////////////////////////////
                            MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Update fees (only callable by vault factory/owner)
    /// @param _managerFee New manager management fee (0-200 basis points)
    /// @param _withdrawalFee New withdrawal fee (0-100 basis points)
    function updateFees(
        uint256 _managerFee,
        uint256 _withdrawalFee
    ) external onlyOwner {
        FeeLogic.validateFeeRates(_managerFee, _withdrawalFee);
        
        managerFee = uint16(_managerFee);
        withdrawalFee = uint16(_withdrawalFee);
    }
    
    /// @notice Update vault settings
    /// @param _maxCapacity New max capacity
    /// @param _minDepositAmount New minimum deposit amount
    function updateVaultSettings(
        uint256 _maxCapacity,
        uint256 _minDepositAmount
    ) external onlyManager {
        (maxCapacity, minDepositAmount) = AssetLogic.updateVaultSettings(
            _maxCapacity,
            _minDepositAmount
        );
    }
    
    /// @notice Update epoch settings
    /// @param _fundraisingDuration New fundraising duration
    /// @param _minFundraisingAmount New minimum fundraising amount
    function updateEpochSettings(
        uint256 _fundraisingDuration,
        uint256 _minFundraisingAmount
    ) external onlyManager {
        (fundraisingDuration, minFundraisingAmount) = AssetLogic.updateEpochSettings(
            _fundraisingDuration,
            _minFundraisingAmount
        );
    }
    
    /// @notice Authorize a strategy
    /// @param _strategy Strategy address
    /// @param _authorized Authorization status
    function setStrategyAuthorization(address _strategy, bool _authorized) external onlyManager {
        authorizedStrategies[_strategy] = _authorized;
    }
    

    // Manager is now immutable after vault creation to prevent rug pulls
    
    /// @notice Update protocol treasury (only callable by factory/owner)
    /// @param _newTreasury New protocol treasury address
    function updateProtocolTreasury(address _newTreasury) external {
        if (msg.sender != owner() && msg.sender != factory) revert Unauthorized(msg.sender, owner());
        if (_newTreasury == address(0)) revert InvalidTreasury(_newTreasury);
        protocolTreasury = _newTreasury;
    }
    
    /// @notice Update oracle protection settings
    /// @param _realizationCooldown New realization cooldown period
    /// @param _maxPriceDeviationBps New max price deviation in basis points
    function updateOracleProtection(
        uint256 _realizationCooldown,
        uint256 _maxPriceDeviationBps
    ) external onlyManager {
        (uint256 newCooldown, uint256 newDeviation) = AssetLogic.updateOracleProtection(
            _realizationCooldown,
            _maxPriceDeviationBps,
            MAX_PRICE_DEVIATION
        );
        realizationCooldown = newCooldown;
        maxPriceDeviationBps = uint16(newDeviation);
        
        emit OracleProtectionUpdated(_realizationCooldown, _maxPriceDeviationBps, emergencyOracleMode);
    }
    
    /// @notice Toggle emergency oracle mode (owner only)
    /// @param _emergencyMode Emergency mode status
    function setEmergencyOracleMode(bool _emergencyMode) external onlyOwner {
        emergencyOracleMode = _emergencyMode;
        emit OracleProtectionUpdated(realizationCooldown, maxPriceDeviationBps, _emergencyMode);
    }
    
    /// @notice Manual price update (owner only, for emergency)
    /// @param _asset Asset address
    /// @param _price New price in USD (18 decimals)
    function setEmergencyPrice(address _asset, uint256 _price) external onlyOwner {
        if (!emergencyOracleMode) revert OnlyInEmergencyMode(emergencyOracleMode);
        if (_price == 0) revert InvalidPrice(_price);
        lastAssetPrices[_asset] = _price;
    }

    /*//////////////////////////////////////////////////////////////
                            EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Emergency pause
    function pause() external onlyManager {
        _pause();
    }
    
    /// @notice Unpause
    function unpause() external onlyManager {
        _unpause();
    }
    

    // Assets can only be withdrawn through proper vault mechanisms (withdrawals, fees)

    /*//////////////////////////////////////////////////////////////
                            RECEIVE FUNCTION
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Allow the vault to receive native ETH directly
    /// @dev Required for operations that return ETH to the vault, such as token->ETH swaps
    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Get number of supported assets
    function getSupportedAssetsCount() external view returns (uint256) {
        return supportedAssets.length;
    }
    
    /// @notice Get all supported assets
    function getAllSupportedAssets() external view returns (address[] memory) {
        return supportedAssets;
    }
    
    /// @notice Get vault info
    function getVaultInfo() external view returns (
        address vaultUnderlyingAsset,
        uint256 totalShares,
        uint256 totalAssetsAmount,
        uint256 sharePrice,
        uint256 maxCap,
        uint256 minDeposit
    ) {
        vaultUnderlyingAsset = asset();
        totalShares = totalSupply();
        totalAssetsAmount = totalAssets();
        sharePrice = totalShares > 0 ? (totalAssetsAmount * 1e18) / totalShares : 1e18;
        maxCap = maxCapacity;
        minDeposit = minDepositAmount;
    }
    
    /// @notice Get epoch info
    function getEpochInfo() external view returns (
        uint256 epoch,
        VaultState state,
        uint256 startTime,
        uint256 startAssets,
        uint256 endAssets
    ) {
        epoch = currentEpoch;
        state = vaultState;
        startTime = epochStartTime;
        startAssets = epochStartAssets[currentEpoch];
        endAssets = epochEndAssets[currentEpoch];
    }
    
    /// @notice Check if vault can go live
    function canGoLive() external view returns (bool) {
        return vaultState == VaultState.FUNDRAISING && totalAssets() >= minFundraisingAmount;
    }
    
    /// @notice Check if all positions are liquidated
    function areAllPositionsLiquidated() external view returns (bool) {
        return _areAllAssetsInUnderlying();
    }
    
    /// @notice Get assets that need liquidation before harvest (public version)
    /// @return assetsToLiquidate Array of asset addresses that need liquidation
    /// @return totalValue Total value of assets to liquidate
    function getAssetsToLiquidate() external view returns (address[] memory assetsToLiquidate, uint256 totalValue) {
        return _getAssetsToLiquidate();
    }
    
    /// @notice Public wrapper for asset value conversion (for try-catch usage)
    /// @param assetAddress Asset to convert
    /// @param amount Amount to convert
    /// @return Value in underlying asset terms
    function convertAssetValueToUnderlying(address assetAddress, uint256 amount) external view returns (uint256) {
        return _convertAssetToUnderlying(assetAddress, amount);
    }
    
    /// @notice Get auto-realization status
    /// @return isRealized Whether profits have been auto-realized
    /// @return realizedAt Timestamp of auto-realization
    /// @return timeToNextRealization Time remaining until next realization is possible
    /// @return hasUnrealizedProfits Whether there are currently unrealized profits
    function getAutoRealizationStatus() external view returns (
        bool isRealized,
        uint256 realizedAt,
        uint256 timeToNextRealization,
        bool hasUnrealizedProfits
    ) {
        isRealized = currentRealization.isRealized;
        realizedAt = currentRealization.realizedAt;
        
        if (isRealized && block.timestamp < realizedAt + realizationCooldown) {
            timeToNextRealization = (realizedAt + realizationCooldown) - block.timestamp;
        } else {
            timeToNextRealization = 0;
        }
        
        hasUnrealizedProfits = vaultState == VaultState.LIVE && 
                              _areAllAssetsInUnderlying() && 
                              _hasUnrealizedProfits();
    }
    
    /// @notice Check if withdrawal will trigger auto-realization
    /// @param /* assets */ Amount user wants to withdraw (unused, kept for interface compatibility)
    /// @return willAutoRealize Whether withdrawal will trigger auto-realization
    /// @return estimatedFeesToPay Estimated fees that will be extracted
    function previewWithdrawalImpact(uint256 /* assets */) external view returns (
        bool willAutoRealize,
        uint256 estimatedFeesToPay
    ) {
        if (vaultState != VaultState.LIVE) {
            return (false, 0);
        }
        
        // Check if auto-realization would be triggered
        willAutoRealize = !currentRealization.isRealized && 
                         _areAllAssetsInUnderlying() && 
                         _hasUnrealizedProfits();
        
        if (willAutoRealize) {
            // Estimate fees that would be extracted
            uint256 currentTotalValue = totalAssets();
            uint256 expectedValue = _getExpectedVaultValue();
            
            if (currentTotalValue > expectedValue) {
                uint256 yield = currentTotalValue - expectedValue;
                
                // Calculate estimated fees using new structure
                (uint256 protocolManagementFee, uint256 managerManagementFee, uint256 managerPerformanceFee, uint256 protocolPerformanceFee) = _calculateAllFees(yield, expectedValue);
                
                estimatedFeesToPay = protocolManagementFee + managerManagementFee + managerPerformanceFee + protocolPerformanceFee;
            }
        }
    }
    
    /// @notice Check if manager needs to call realizeByManager() or if auto-realization is sufficient
    /// @return needsManualRealization Whether manager should call realizeByManager()
    /// @return reason Explanation of why manual realization is/isn't needed
    /// @return cooldownRemaining Time remaining in cooldown (if any)
    function shouldManagerRealize() external view returns (
        bool needsManualRealization,
        string memory reason,
        uint256 cooldownRemaining
    ) {
        if (vaultState != VaultState.LIVE) {
            return (false, "Not in LIVE state", 0);
        }
        
        if (!_areAllAssetsInUnderlying()) {
            return (true, "Must liquidate positions first", 0);
        }
        
        if (!_hasUnrealizedProfits()) {
            return (false, "No unrealized profits to realize", 0);
        }
        
        // Check if in cooldown period
        if (block.timestamp < lastRealizationTime + realizationCooldown) {
            cooldownRemaining = (lastRealizationTime + realizationCooldown) - block.timestamp;
            return (false, "Still in cooldown period", cooldownRemaining);
        }
        
        // Check if already auto-realized recently
        if (currentRealization.isRealized && 
            block.timestamp < currentRealization.realizedAt + realizationCooldown) {
            cooldownRemaining = (currentRealization.realizedAt + realizationCooldown) - block.timestamp;
            return (false, "Already auto-realized, still in cooldown", cooldownRemaining);
        }
        
        return (true, "Manual realization recommended", 0);
    }

    /*//////////////////////////////////////////////////////////////
                            VERSION FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Get implementation version
    function version() external pure returns (string memory) {
        return "1.1.0";
    }

    /*//////////////////////////////////////////////////////////////
                        IHAS SUPPORTED ASSET IMPLEMENTATION
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Get all supported assets (IHasSupportedAsset implementation)
    /// @return Array of supported asset addresses
    function getSupportedAssets() external view override returns (address[] memory) {
        return supportedAssets;
    }
    
    /// @notice Check if asset is supported by this vault (IHasSupportedAsset implementation)
    /// @param asset Asset address to check
    /// @return True if asset is supported by this vault
    function isSupportedAsset(address asset) external view override returns (bool) {
        return isAssetSupported[asset];
    }
    
    /// @notice Get asset type from factory (IHasSupportedAsset implementation)
    /// @param asset Asset address
    /// @return Asset type as defined in factory (same source as guard resolution)
    function getAssetType(address asset) external view override returns (uint16) {
        return IVaultFactory(factory).getTokenType(asset);
    }

    /*//////////////////////////////////////////////////////////////
                           WITHDRAWAL FEE PREVIEW
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Preview withdrawal amount after fees
    /// @param assets Amount of assets to withdraw
    /// @return assetsAfterFee Amount user will receive after fees
    function previewWithdrawalAfterFees(uint256 assets) external view returns (uint256 assetsAfterFee) {
        uint256 fee = FeeLogic.calculateWithdrawalFee(assets, withdrawalFee, FEE_DENOMINATOR);
        return assets - fee;
    }
} 
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
import "./interfaces/IVaultFactory.sol";
import "./interfaces/IAssetHandler.sol";
import "./interfaces/IHasGuardInfo.sol";
import "./interfaces/IHasSupportedAsset.sol";
import "./interfaces/guards/IAssetGuard.sol";
import "./interfaces/guards/IGuard.sol";
import "./interfaces/guards/ITxTrackingGuard.sol";
import "./utils/VaultLogic.sol";
import "./utils/FeeLogic.sol";

/// @title Strtm (Str.) Vault
/// @notice A vault contract for yield farming and asset management with epoch-based lifecycle
contract Vault is 
    ERC4626Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IHasSupportedAsset
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/
    
    error OnlyManager();
    error UnauthorizedStrategy();
    error InvalidVaultState();
    error InvalidAsset();
    error InvalidManager();
    error ManagementFeeTooHigh();
    error PerformanceFeeTooHigh();
    error InsufficientFundsRaised();
    error MustLiquidateAllPositions();
    error AssetGuardNotFound();
    error InvalidUnderlyingPriceFeed();
    error NoEmergencyPriceAvailable();
    error DepositsOnlyDuringFundraising();
    error BelowMinimumDeposit();
    error ExceedsCapacity();
    error InsufficientUnderlyingAssets();
    error InvalidTarget();
    error NoGuardFound();
    error PlatformNotSupported();
    error AssetNotSupported();
    error TransactionRejectedByGuard();
    error ContractCallFailed();
    error RealizationCooldownActive();
    error ManualLiquidationRequired();
    error InternalOnly();
    error CannotRemoveUnderlyingAsset();
    error AssetAlreadySupported();
    error InvalidPlatformName();
    error PlatformAlreadySupported();
    error CooldownTooLong();
    error DeviationTooHigh();
    error OnlyInEmergencyMode();
    error InvalidPrice();
    error Unauthorized();
    error InvalidTreasury();

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
    
    event EmergencyOracleModeActivated();
    
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
    
    event AutoRealizationTriggered(
        address indexed triggeredBy,
        uint256 preRealizationValue,
        uint256 totalFeesExtracted,
        uint256 blockNumber
    );

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
    

    uint16 public managementFee; // Annual management fee (basis points) - max 65535 > max fee 2000
    uint16 public performanceFee; // Performance fee (basis points) - max 65535 > max fee 2000
    uint16 public withdrawalFee; // Withdrawal fee (basis points) - max 65535 > max fee 2000
    uint16 public protocolFee; // Protocol fee taken from performance fee (basis points) - max 65535 > max fee 5000
    uint256 public constant MAX_FEE = 65535;
    uint256 public constant MAX_PROTOCOL_FEE = 5000; // 50% max protocol fee share
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
        if (msg.sender != manager) revert OnlyManager();
        _;
    }
    
    modifier onlyAuthorizedStrategy() {
        if (!authorizedStrategies[msg.sender] && msg.sender != manager) revert UnauthorizedStrategy();
        _;
    }
    
    modifier onlyInState(VaultState _state) {
        if (vaultState != _state) revert InvalidVaultState();
        _;
    }
    
    modifier onlyInStates(VaultState _state1, VaultState _state2) {
        if (vaultState != _state1 && vaultState != _state2) revert InvalidVaultState();
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
    /// @param _managementFee Annual management fee (basis points)
    /// @param _performanceFee Performance fee (basis points)
    function initialize(
        string memory _name,
        string memory _symbol,
        address _underlyingAsset,
        address _manager,
        uint256 _maxCapacity,
        uint256 _managementFee,
        uint256 _performanceFee
    ) public initializer {
        _initializeContracts(_name, _symbol, _underlyingAsset);
        _validateInitParams(_underlyingAsset, _manager, _managementFee, _performanceFee);
        _setBasicParams(_underlyingAsset, _manager, _maxCapacity);
        _initializeEpochAndState();
        _setCustomFees(_managementFee, _performanceFee);
        _setOracleProtectionDefaults();
        _setDefaultAmounts(_underlyingAsset);
        _initializeRealizationState();
        _addSupportedAsset(_underlyingAsset);
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
    function _validateInitParams(address _underlyingAsset, address _manager, uint256 _managementFee, uint256 _performanceFee) internal pure {
        if (_underlyingAsset == address(0)) revert InvalidAsset();
        if (_manager == address(0)) revert InvalidManager();
        if (_managementFee > MAX_FEE) revert ManagementFeeTooHigh();
        if (_performanceFee > MAX_FEE) revert PerformanceFeeTooHigh();
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
    
    /// @notice Set custom fee structure
    function _setCustomFees(uint256 _managementFee, uint256 _performanceFee) internal {
        managementFee = uint16(_managementFee);
        performanceFee = uint16(_performanceFee);
        withdrawalFee = 50; // 0.5% default withdrawal fee
        protocolFee = 1000; // 10% of performance fee (default)
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
        if (totalAssets() < minFundraisingAmount) revert InsufficientFundsRaised();
        
        VaultState oldState = vaultState;
        vaultState = VaultState.LIVE;
        epochStartAssets[currentEpoch] = totalAssets();
        
        emit StateChanged(currentEpoch, oldState, vaultState, block.timestamp);
    }
    
    /// @notice Return to FUNDRAISING state (must liquidate all positions first)
    function returnToFundraising() external onlyManager onlyInState(VaultState.LIVE) {
        // Ensure all assets are back to underlying asset
        if (!_areAllAssetsInUnderlying()) revert MustLiquidateAllPositions();
        
        VaultState oldState = vaultState;
        vaultState = VaultState.FUNDRAISING;
        
        emit StateChanged(currentEpoch, oldState, vaultState, block.timestamp);
    }
    
    /// @notice Advance to next epoch (must return to underlying asset first)
    function advanceEpoch() external onlyManager onlyInState(VaultState.FUNDRAISING) {
        // Ensure all assets are in underlying asset
        if (!_areAllAssetsInUnderlying()) revert MustLiquidateAllPositions();
        
        uint256 oldEpoch = currentEpoch;
        uint256 currentTotalAssets = totalAssets();
        epochEndAssets[oldEpoch] = currentTotalAssets;
        
        currentEpoch++;
        epochStartTime = block.timestamp;
        epochStartAssets[currentEpoch] = currentTotalAssets;
        
        emit EpochAdvanced(oldEpoch, currentEpoch, currentTotalAssets, block.timestamp);
    }
    
    /// @notice Check if all vault assets are in underlying asset
    function _areAllAssetsInUnderlying() internal view returns (bool) {
        return VaultLogic.areAllAssetsInUnderlying(address(this), factory, asset(), supportedAssets);
    }
    
    /// @notice Force liquidation of all positions (emergency only)
    function emergencyLiquidateAll() external onlyOwner {
        // This should call liquidation strategies for all non-underlying assets
        // Implementation depends on specific strategy contracts
        vaultState = VaultState.FUNDRAISING;
        emit StateChanged(currentEpoch, VaultState.LIVE, VaultState.FUNDRAISING, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                          ASSET GUARD FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Get accurate balance of an asset using guards
    /// @param asset Asset address
    /// @return Balance of the asset (handles external contracts via guards)
    function assetBalance(address asset) public view returns (uint256) {
        return _assetBalance(asset);
    }

    /// @notice Internal function to get balance of an asset via guards
    /// @param asset Asset address
    /// @return Balance of the asset
    function _assetBalance(address asset) internal view returns (uint256) {
        return VaultLogic.getAssetBalance(address(this), asset, factory);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Total amount of underlying assets held by the vault
    function totalAssets() public view override returns (uint256) {
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
        uint256 underlyingPriceUSD = _getValidatedPrice(assetHandlerAddr, cachedUnderlyingAsset);
        uint8 underlyingDecimals = IERC20Metadata(cachedUnderlyingAsset).decimals();
        
        // Early return if invalid underlying price
        if (underlyingPriceUSD <= 0) return underlyingBalance;
        

        for (uint256 i = 0; i < assetsLength;) {
            address currentAsset = supportedAssets[i];
            
            // Skip underlying asset (already counted)
            if (currentAsset != cachedUnderlyingAsset) {
                uint256 balance = _assetBalance(currentAsset);
                
    
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

    /// @notice Convert asset amount to underlying asset value using guards (original version for single calls)
    /// @param assetAddress The asset to convert
    /// @param amount Amount of the asset
    /// @return Value in underlying asset terms
    function _convertAssetToUnderlying(address assetAddress, uint256 amount) internal view returns (uint256) {
        if (assetAddress == asset()) return amount;
        
        // All supported assets must have guards - no fallback needed
        // This is enforced by the vault's asset management system
        (address guard, ) = IHasGuardInfo(factory).getGuard(assetAddress);
        if (guard == address(0)) revert AssetGuardNotFound();
        
        // Use guard to calculate the accurate value
        // Guard knows the true value of the asset (whether representative token or simple token)
        uint256 trueValueUSD = IAssetGuard(guard).calcValue(address(this), assetAddress, amount);
        
        // Convert the USD value to underlying asset terms
        address assetHandlerAddr = IVaultFactory(factory).getAssetHandler();
        uint256 underlyingPriceUSD = _getValidatedPrice(assetHandlerAddr, asset());
        if (underlyingPriceUSD <= 0) revert InvalidUnderlyingPriceFeed();
        
        uint8 underlyingDecimals = IERC20Metadata(asset()).decimals();
        uint256 valueInUnderlying = (trueValueUSD * (10 ** underlyingDecimals)) / underlyingPriceUSD;
        
        return valueInUnderlying;
    }
    
    /// @notice Get validated price with protection against manipulation
    /// @param assetHandlerAddr AssetHandler address
    /// @param assetAddr Asset address
    /// @return Validated price
    function _getValidatedPrice(address assetHandlerAddr, address assetAddr) internal view returns (uint256) {
        if (emergencyOracleMode) {
            // In emergency mode, use last known prices
            uint256 emergencyPrice = lastAssetPrices[assetAddr];
            if (emergencyPrice <= 0) revert NoEmergencyPriceAvailable();
            return emergencyPrice;
        }
        
        uint256 currentPrice = IAssetHandler(assetHandlerAddr).getUSDPrice(assetAddr);
        uint256 lastPrice = lastAssetPrices[assetAddr];
        
        // For first time or when no last price exists, allow current price
        if (lastPrice == 0) {
            return currentPrice;
        }
        
        // Check price deviation protection
        uint256 priceChange = currentPrice > lastPrice ? 
            ((currentPrice - lastPrice) * 10000) / lastPrice :
            ((lastPrice - currentPrice) * 10000) / lastPrice;
            
        // If price change exceeds threshold, use last known price for safety
        if (priceChange > maxPriceDeviationBps) {
            return lastPrice; // Use last known safe price
        }
        
        return currentPrice;
    }
    
    /// @notice Get vault breakdown by asset
    /// @return assetAddresses Array of asset addresses
    /// @return assetBalances Array of asset balances  
    /// @return assetValues Array of values in underlying asset terms
    function getVaultAssetBreakdown() external view returns (
        address[] memory assetAddresses,
        uint256[] memory assetBalances,
        uint256[] memory assetValues
    ) {
        return VaultLogic.getVaultAssetBreakdown(
            address(this),
            factory,
            asset(),
            supportedAssets,
            lastAssetPrices,
            emergencyOracleMode,
            maxPriceDeviationBps
        );
    }

    /// @notice Maximum deposit limit
    function maxDeposit(address) public view override returns (uint256) {
        if (paused()) return 0;
        
        // No deposits allowed in LIVE state except for yield/rewards
        if (vaultState == VaultState.LIVE) return 0;
        
        uint256 currentTotalAssets = totalAssets();
        return maxCapacity > currentTotalAssets ? maxCapacity - currentTotalAssets : 0;
    }

    /// @notice Maximum withdrawal limit
    function maxWithdraw(address owner) public view override returns (uint256) {
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
    function previewDeposit(uint256 assets) public view override returns (uint256) {
        if (vaultState != VaultState.FUNDRAISING) revert DepositsOnlyDuringFundraising();
        if (assets < minDepositAmount) revert BelowMinimumDeposit();
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /// @notice Preview withdrawal with fees
    function previewWithdraw(uint256 assets) public view override returns (uint256) {
        (uint256 assetsWithFee, ) = FeeLogic.previewWithdrawalFees(assets, withdrawalFee, FEE_DENOMINATOR);
        return _convertToShares(assetsWithFee, Math.Rounding.Ceil);
    }

    /// @notice Deposit assets and receive shares (only during fundraising)
    function deposit(uint256 assets, address receiver) public override whenNotPaused onlyInState(VaultState.FUNDRAISING) returns (uint256) {
        if (assets < minDepositAmount) revert BelowMinimumDeposit();
        if (totalAssets() + assets > maxCapacity) revert ExceedsCapacity();
        
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
    
    /// @notice Perform single profit realization (internal)
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
        
        // Calculate fees
        uint256 timeElapsed = block.timestamp - lastRealizationTime;
        uint256 managementFeeAmount = (expectedValue * managementFee * timeElapsed) / 
                                     (365 days * FEE_DENOMINATOR);
        uint256 performanceFeeAmount = (yield * performanceFee) / FEE_DENOMINATOR;
        uint256 protocolFeeAmount = (performanceFeeAmount * protocolFee) / FEE_DENOMINATOR;
        uint256 managerPerformanceFee = performanceFeeAmount - protocolFeeAmount;
        
        // Extract fees
        _extractFeesFromUnderlying(managementFeeAmount, managerPerformanceFee, protocolFeeAmount);
        
        // Update timestamp
        lastRealizationTime = block.timestamp;
        
        emit YieldHarvested(address(this), asset(), yield, managementFeeAmount, performanceFeeAmount, protocolFeeAmount);
    }

    /// @notice Withdraw assets by burning shares
    function withdraw(uint256 assets, address receiver, address owner) public override whenNotPaused onlyInStates(VaultState.FUNDRAISING, VaultState.LIVE) returns (uint256) {
        // Smart auto-realize profits before withdrawal in LIVE state
        if (vaultState == VaultState.LIVE) {
            _smartAutoRealize();
            
            uint256 maxWithdrawable = maxWithdraw(owner);
            if (assets > maxWithdrawable) revert InsufficientUnderlyingAssets();
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
        
        // Calculate withdrawal fee
        uint256 fee = (assets * withdrawalFee) / FEE_DENOMINATOR;
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
        if (target == address(0)) revert InvalidTarget();
        
        // Get guard for this target contract
        (address guard, string memory platform) = IHasGuardInfo(factory).getGuard(target);
        if (guard == address(0)) revert NoGuardFound();
        
        // Determine if this is a platform or asset guard
        bool isPlatform = bytes(platform).length > 0;
        
        if (isPlatform) {
            // Platform guard - check if platform is supported
            if (!_isSupportedPlatform(platform)) revert PlatformNotSupported();
        } else {
            // Asset guard - check if asset is supported
            if (!_isSupportedAsset(target)) revert AssetNotSupported();
        }
        
        // Execute guard validation
        uint16 txType;
        if (value > 0) {
            txType = IGuard(guard).txGuard(address(this), target, data, value);
        } else {
            txType = IGuard(guard).txGuard(address(this), target, data);
        }
        if (txType == 0) revert TransactionRejectedByGuard();
        
        // Execute the call
        (bool success, bytes memory resultData) = target.call{value: value}(data);
        if (!success) revert ContractCallFailed();
        
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
        
        uint256 yield = _calculateAndLimitYield(currentTotalValue, expectedValue);
        (uint256 managementFeeAmount, uint256 managerPerformanceFee, uint256 protocolFeeAmount) = _calculateAllFees(yield, expectedValue);
        
        _extractFeesFromUnderlying(managementFeeAmount, managerPerformanceFee, protocolFeeAmount);
        _finalizeRealization();
        
        emit YieldHarvested(address(this), asset(), yield, managementFeeAmount, managementFeeAmount + managerPerformanceFee, protocolFeeAmount);
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
        if (block.timestamp < lastRealizationTime + realizationCooldown) revert RealizationCooldownActive();
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
    
    /// @notice Calculate and limit yield to reasonable amount
    /// @param currentTotalValue Current vault value
    /// @param expectedValue Expected value without yield
    /// @return Limited yield amount
    function _calculateAndLimitYield(uint256 currentTotalValue, uint256 expectedValue) internal pure returns (uint256) {
        return VaultLogic.calculateAndLimitYield(currentTotalValue, expectedValue);
    }
    
    /// @notice Calculate all fee components
    /// @param yield Realized yield amount
    /// @param expectedValue Expected vault value
    /// @return managementFeeAmount Management fee
    /// @return managerPerformanceFee Manager's share of performance fee
    /// @return protocolFeeAmount Protocol's share of performance fee
    function _calculateAllFees(uint256 yield, uint256 expectedValue) internal view returns (
        uint256 managementFeeAmount,
        uint256 managerPerformanceFee, 
        uint256 protocolFeeAmount
    ) {
        uint256 timeElapsed = block.timestamp - lastRealizationTime;
        managementFeeAmount = FeeLogic.calculateManagementFee(
            expectedValue, managementFee, timeElapsed, FEE_DENOMINATOR
        );
        
        (managerPerformanceFee, protocolFeeAmount) = FeeLogic.calculatePerformanceFees(
            yield, performanceFee, protocolFee, FEE_DENOMINATOR
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
            
            revert ManualLiquidationRequired();
        }
    }
    
    /// @notice Check and verify all positions are liquidated for harvest
    /// @dev Manager must manually liquidate positions via callContract() before calling this
    function liquidateAllPositionsForHarvest() external onlyManager {
        // Get positions that need liquidation
        (address[] memory assetsToLiquidate, uint256 totalValue) = _getAssetsToLiquidate();
        
        if (assetsToLiquidate.length > 0) {
            // Still have positions to liquidate - provide guidance
            revert ManualLiquidationRequired();
        }
        
        // All positions are liquidated
        emit AllPositionsLiquidated(totalValue, block.timestamp);
    }
    
    /// @notice Get assets that need to be liquidated for harvest
    /// @return assetsToLiquidate Array of asset addresses with non-zero balances
    /// @return totalValue Total value of non-underlying assets
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
    
    /// @notice Extract fees from underlying asset (used after harvest when all assets are underlying)
    /// @dev All assets should already be in underlying asset due to business logic protection
    function _extractFeesFromUnderlying(uint256 managementFeeAmount, uint256 managerPerformanceFee, uint256 protocolFeeAmount) internal {
        FeeLogic.extractFeesFromUnderlying(
            asset(),
            address(this),
            manager,
            protocolTreasury,
            managementFeeAmount,
            managerPerformanceFee,
            protocolFeeAmount
        );
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
        if (msg.sender != address(this)) revert InternalOnly();
        
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
    
    /// @notice Remove a supported asset
    /// @param _asset Asset to remove
    function removeSupportedAsset(address _asset) external onlyManager {
        if (_asset == asset()) revert CannotRemoveUnderlyingAsset();
        if (!isAssetSupported[_asset]) revert AssetNotSupported();
        
        // Remove from array
        uint256 index = assetPosition[_asset];
        address lastAsset = supportedAssets[supportedAssets.length - 1];
        
        supportedAssets[index] = lastAsset;
        assetPosition[lastAsset] = index;
        supportedAssets.pop();
        
        delete assetPosition[_asset];
        isAssetSupported[_asset] = false;
    }
    
    /// @notice Internal function to add supported asset with factory whitelist validation
    /// @param _asset Asset to add
    function _addSupportedAsset(address _asset) internal {
        if (_asset == address(0)) revert InvalidAsset();
        if (isAssetSupported[_asset]) revert AssetAlreadySupported();
        
        // 🛡️ SECURITY: Check factory whitelist before allowing asset
        if (!IVaultFactory(factory).isAssetWhitelisted(_asset)) {
            revert AssetNotSupported(); // Asset not whitelisted by factory
        }
        
        supportedAssets.push(_asset);
        assetPosition[_asset] = supportedAssets.length - 1;
        isAssetSupported[_asset] = true;
    }

    /*//////////////////////////////////////////////////////////////
                            PLATFORM MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Add a supported platform
    /// @param _platform Platform name to add
    function addSupportedPlatform(string memory _platform) external onlyManager {
        if (bytes(_platform).length == 0) revert InvalidPlatformName();
        if (isPlatformSupported[_platform]) revert PlatformAlreadySupported();
        
        supportedPlatforms.push(_platform);
        isPlatformSupported[_platform] = true;
    }
    
    /// @notice Remove a supported platform
    /// @param _platform Platform name to remove
    function removeSupportedPlatform(string memory _platform) external onlyManager {
        if (!isPlatformSupported[_platform]) revert PlatformNotSupported();
        
        // Find and remove from array
        for (uint256 i = 0; i < supportedPlatforms.length; i++) {
            if (keccak256(bytes(supportedPlatforms[i])) == keccak256(bytes(_platform))) {
                // Move last element to this position
                supportedPlatforms[i] = supportedPlatforms[supportedPlatforms.length - 1];
                supportedPlatforms.pop();
                break;
            }
        }
        
        isPlatformSupported[_platform] = false;
    }

    /*//////////////////////////////////////////////////////////////
                            MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Update fees (only callable by vault factory/owner)
    /// @param _managementFee New management fee
    /// @param _performanceFee New performance fee
    /// @param _withdrawalFee New withdrawal fee
    /// @param _protocolFee New protocol fee share
    function updateFees(
        uint256 _managementFee,
        uint256 _performanceFee,
        uint256 _withdrawalFee,
        uint256 _protocolFee
    ) external onlyOwner {
        FeeLogic.validateFeeRates(
            _managementFee,
            _performanceFee,
            _withdrawalFee,
            _protocolFee,
            MAX_FEE,
            MAX_PROTOCOL_FEE
        );
        
        managementFee = uint16(_managementFee);
        performanceFee = uint16(_performanceFee);
        withdrawalFee = uint16(_withdrawalFee);
        protocolFee = uint16(_protocolFee);
    }
    
    /// @notice Update vault settings
    /// @param _maxCapacity New max capacity
    /// @param _minDepositAmount New minimum deposit amount
    function updateVaultSettings(
        uint256 _maxCapacity,
        uint256 _minDepositAmount
    ) external onlyManager {
        maxCapacity = _maxCapacity;
        minDepositAmount = _minDepositAmount;
    }
    
    /// @notice Update epoch settings
    /// @param _fundraisingDuration New fundraising duration
    /// @param _minFundraisingAmount New minimum fundraising amount
    function updateEpochSettings(
        uint256 _fundraisingDuration,
        uint256 _minFundraisingAmount
    ) external onlyManager {
        fundraisingDuration = _fundraisingDuration;
        minFundraisingAmount = _minFundraisingAmount;
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
        if (msg.sender != owner() && msg.sender != factory) revert Unauthorized();
        if (_newTreasury == address(0)) revert InvalidTreasury();
        protocolTreasury = _newTreasury;
    }
    
    /// @notice Update oracle protection settings
    /// @param _realizationCooldown New realization cooldown period
    /// @param _maxPriceDeviationBps New max price deviation in basis points
    function updateOracleProtection(
        uint256 _realizationCooldown,
        uint256 _maxPriceDeviationBps
    ) external onlyManager {
        if (_realizationCooldown > 24 hours) revert CooldownTooLong();
        if (_maxPriceDeviationBps > MAX_PRICE_DEVIATION) revert DeviationTooHigh();
        
        realizationCooldown = _realizationCooldown;
        maxPriceDeviationBps = uint16(_maxPriceDeviationBps);
        
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
        if (!emergencyOracleMode) revert OnlyInEmergencyMode();
        if (_price == 0) revert InvalidPrice();
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
                
                // Calculate estimated fees
                uint256 timeElapsed = block.timestamp - lastRealizationTime;
                uint256 managementFeeAmount = (expectedValue * managementFee * timeElapsed) / 
                                             (365 days * FEE_DENOMINATOR);
                uint256 performanceFeeAmount = (yield * performanceFee) / FEE_DENOMINATOR;
                
                estimatedFeesToPay = managementFeeAmount + performanceFeeAmount;
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
                            INTERNAL HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Check if asset is supported by this vault
    /// @param _asset Asset address to check
    /// @return True if asset is supported by this vault
    function _isSupportedAsset(address _asset) internal view returns (bool) {
        return isAssetSupported[_asset];
    }
    
    /// @notice Check if platform is supported
    /// @param _platform Platform name to check
    /// @return True if platform is supported
    function _isSupportedPlatform(string memory _platform) internal view returns (bool) {
        for (uint256 i = 0; i < supportedPlatforms.length; i++) {
            if (keccak256(bytes(supportedPlatforms[i])) == keccak256(bytes(_platform))) {
                return true;
            }
        }
        return false;
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
} 
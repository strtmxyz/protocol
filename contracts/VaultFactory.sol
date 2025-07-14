// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IVaultFactory.sol";
import "./interfaces/IAggregatorV3Interface.sol";
import "./interfaces/IAssetHandler.sol";    
import "./interfaces/IHasAssetInfo.sol";
import "./interfaces/IHasGuardInfo.sol";
import "./interfaces/IHasPausable.sol";
import "./interfaces/IHasOwnable.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/guards/IPlatformGuard.sol";
import "./interfaces/guards/IAssetGuard.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

// Authorization errors
error OnlyVaultManager(address caller, address vault, address expectedManager);
error Unauthorized(address caller, address expected);

// Asset validation errors
error InvalidAsset(address asset);
error AssetNotWhitelisted(address asset);
error InvalidAssetForType(address asset, uint16 assetType);
error AssetAlreadyAdded(address asset);
error AssetNotInList(address asset, uint256 arrayLength);
error TooManyDecimals(uint8 decimals, uint8 maxDecimals);

// Parameter validation errors
error InvalidManager(address manager);
error InvalidGovernanceAddress(address governance);
error InvalidTreasuryAddress(address treasury);
error InvalidAdminAddress(address admin);
error InvalidAssetHandler(address assetHandler);
error InvalidImplementation(address implementation);
error InvalidAddress(address addr, string context);

// Capacity/limit errors
error BelowMinCapacity(uint256 requested, uint256 minimum);
error AboveMaxCapacity(uint256 requested, uint256 maximum);
error InvalidLimits(uint256 minLimit, uint256 maxLimit);

// Fee validation errors
error InsufficientCreationFee(uint256 sent, uint256 required);
error ManagementFeeExceedsMax(uint256 requested, uint256 maximum);
error PerformanceFeeExceedsMax(uint256 requested, uint256 maximum);
error WithdrawalFeeExceedsMax(uint256 requested, uint256 maximum);
error ProtocolFeeExceedsMax(uint256 requested, uint256 maximum);

// Operation errors
error NotAVault(address vault);
error FeeTransferFailed(address to, uint256 amount);
error NativeTokenRecoveryFailed(address to, uint256 amount);
error ArrayLengthMismatch(uint256 arrayLength1, uint256 arrayLength2);
error VersionTooLow(uint256 currentVersion, uint256 minimumVersion);

/// @title Vault Factory
/// @notice Factory contract for creating and managing vaults
contract VaultFactory is 
    IVaultFactory,
    IHasGuardInfo,
    IHasAssetInfo,
    OwnableUpgradeable,
    PausableUpgradeable
{
    

    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    address public proxyAdmin;
    address public vaultImplementation;
    uint32 public implementationVersion;
    
    // Vault registry
    address[] public deployedVaults;
    mapping(address => bool) public isVault;
    mapping(address => address) public vaultManager;
    mapping(address => uint256) public vaultIndex;
    
    // Underlying assets (can be used as vault base asset)
    mapping(address => bool) public underlyingAssetAllowed;
    address[] public underlyingAssets;
    mapping(address => uint256) public underlyingAssetIndex;

    // All whitelisted assets (can be held in vaults)
    mapping(address => bool) public assetWhitelisted;
    mapping(address => uint16) public tokenType;
    address[] public whitelistedAssets;
    mapping(address => uint256) public assetIndex;
    
    address public governance;
    address public treasury;    
    address public admin;

    address internal _assetHandler;
    uint256 internal _maximumSupportedAssetCount;

    mapping(address => uint256) public vaultVersion;
    uint256 public vaultStorageVersion;

    // Factory settings
    uint256 public maxCapacityLimit;
    uint256 public minCapacityLimit;
    uint256 public creationFee;
    
    // Governance system
    mapping(bytes32 => address) public governanceAddresses; // governance address mappings
    
    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/
    
    modifier onlyVaultManager(address _vault) {
        if (vaultManager[_vault] != msg.sender) revert OnlyVaultManager(msg.sender, _vault, vaultManager[_vault]);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Initialize the vault factory
    /// @param assetHandler Asset handler address
    /// @param _treasury Treasury address
    /// @param _governance Governance address
    function initialize(
        address assetHandler,
        address _treasury,
        address _governance
    ) public initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        
        _assetHandler = assetHandler;
        treasury = _treasury;
        governance = _governance;
        admin = msg.sender;
        
        ProxyAdmin _proxyAdmin = new ProxyAdmin(address(this));
        proxyAdmin = address(_proxyAdmin);
        
        // vaultImplementation will be set later via updateVaultImplementation
        implementationVersion = 1;
        
        // Default limits (in native token terms, assuming 18 decimals)
        maxCapacityLimit = 10_000_000 * 1e18; // 10M max
        minCapacityLimit = 1_000 * 1e18; // 1K min
        creationFee = 0.01 ether; // 0.01 ETH creation fee

        _maximumSupportedAssetCount = 12;
        vaultStorageVersion = 110; // V1.1.0
    }

    /*//////////////////////////////////////////////////////////////
                            CAPACITY CALCULATION HELPERS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Adjust capacity limit based on underlying asset decimals
    /// @param baseLimit The base limit (stored with 18 decimals, e.g., 10M * 1e18)
    /// @param assetDecimals Decimals of the underlying asset
    /// @return adjustedLimit Capacity limit adjusted for asset decimals
    function _getAdjustedCapacityLimit(uint256 baseLimit, uint8 assetDecimals) internal pure returns (uint256 adjustedLimit) {
        // Base limit represents: amount * 1e18 (e.g., 10M * 1e18)
        // We want: amount * 10^assetDecimals (e.g., 10M * 1e6 for USDC)
        // Formula: (baseLimit / 1e18) * 10^assetDecimals = baseLimit * 10^assetDecimals / 1e18
        
        if (assetDecimals <= 18) {
            // For smaller decimals: divide by the difference
            // Example: 10M * 1e18 -> 10M * 1e6 = (10M * 1e18) / 1e12
            adjustedLimit = baseLimit / (10 ** (18 - assetDecimals));
        } else {
            // For larger decimals: multiply by the difference (should not happen due to validation)
            adjustedLimit = baseLimit * (10 ** (assetDecimals - 18));
        }
    }
    
    /// @notice Get adjusted max capacity limit for a specific underlying asset
    /// @param underlyingAsset The underlying asset address
    /// @return adjustedLimit Max capacity limit adjusted for asset decimals
    function getAdjustedMaxCapacityLimit(address underlyingAsset) external view returns (uint256 adjustedLimit) {
        uint8 decimals = IERC20Metadata(underlyingAsset).decimals();
        return _getAdjustedCapacityLimit(maxCapacityLimit, decimals);
    }
    
    /// @notice Get adjusted min capacity limit for a specific underlying asset
    /// @param underlyingAsset The underlying asset address
    /// @return adjustedLimit Min capacity limit adjusted for asset decimals
    function getAdjustedMinCapacityLimit(address underlyingAsset) external view returns (uint256 adjustedLimit) {
        uint8 decimals = IERC20Metadata(underlyingAsset).decimals();
        return _getAdjustedCapacityLimit(minCapacityLimit, decimals);
    }

    /*//////////////////////////////////////////////////////////////
                            VAULT CREATION
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Create a new ERC-4626 vault
    /// @param _name Name of the vault token
    /// @param _symbol Symbol of the vault token
    /// @param _underlyingAsset Underlying asset address
    /// @param _manager Manager address
    /// @param _maxCapacity Maximum capacity of the vault
    /// @param _managerFee Manager management fee (basis points, 0-200 for 0-2%)
    /// @param _withdrawalFee Withdrawal fee (basis points, 0-100 for 0-1%)
    /// @return vault Address of the created vault
    function createVault(
        string memory _name,
        string memory _symbol,
        address _underlyingAsset,
        address _manager,
        uint256 _maxCapacity,
        uint256 _managerFee,
        uint256 _withdrawalFee
    ) external payable whenNotPaused returns (address vault) {
    
        if (msg.value < creationFee) revert InsufficientCreationFee(msg.value, creationFee);
        if (!underlyingAssetAllowed[_underlyingAsset]) revert AssetNotWhitelisted(_underlyingAsset);
        if (_manager == address(0)) revert InvalidManager(_manager);
        // Validate asset decimals first
        uint8 decimals = IERC20Metadata(_underlyingAsset).decimals();
        if (decimals > 18) revert TooManyDecimals(decimals, 18);
        
        // Calculate capacity limits based on underlying asset decimals
        uint256 adjustedMinLimit = _getAdjustedCapacityLimit(minCapacityLimit, decimals);
        uint256 adjustedMaxLimit = _getAdjustedCapacityLimit(maxCapacityLimit, decimals);
        
        if (_maxCapacity < adjustedMinLimit) revert BelowMinCapacity(_maxCapacity, adjustedMinLimit);
        if (_maxCapacity > adjustedMaxLimit) revert AboveMaxCapacity(_maxCapacity, adjustedMaxLimit);
        
        // Validate fees using new structure
        if (_managerFee > 200) revert ManagementFeeExceedsMax(_managerFee, 200);
        if (_withdrawalFee > 100) revert WithdrawalFeeExceedsMax(_withdrawalFee, 100);
        
        // Transfer creation fee to treasury
        if (msg.value > 0) {
            (bool success, ) = treasury.call{value: msg.value}("");
            if (!success) revert FeeTransferFailed(treasury, msg.value);
        }
        
        // Create vault proxy
        bytes memory initData = abi.encodeWithSelector(
            IVault.initialize.selector,
            _name,
            _symbol,
            _underlyingAsset,
            _manager,
            _maxCapacity,
            _managerFee,
            _withdrawalFee
        );
        
        vault = address(new TransparentUpgradeableProxy(
            vaultImplementation,
            proxyAdmin,
            initData
        ));
        
        // Register vault
        deployedVaults.push(vault);
        isVault[vault] = true;
        vaultManager[vault] = _manager;
        vaultIndex[vault] = deployedVaults.length - 1;
        
        emit VaultCreated(vault, _manager, _underlyingAsset, _name, _symbol, _maxCapacity);
    }

    /*//////////////////////////////////////////////////////////////
                            ASSET MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Whitelist an asset (for holding in vaults)
    /// @param _asset Asset address
    /// @param _tokenType Token type (e.g., 1=ERC20, 2=LP token, etc.)
    /// @param _allowed Whether the asset is allowed
    function setAssetWhitelist(
        address _asset,
        uint16 _tokenType,
        bool _allowed
    ) external onlyOwner {
        if (_asset == address(0)) revert InvalidAsset(_asset);
        
        bool wasWhitelisted = assetWhitelisted[_asset];
        assetWhitelisted[_asset] = _allowed;
        
        if (_allowed && !wasWhitelisted) {
            // Add to whitelist
            whitelistedAssets.push(_asset);
            assetIndex[_asset] = whitelistedAssets.length - 1;
            tokenType[_asset] = _tokenType;
        } else if (!_allowed && wasWhitelisted) {
            // Remove from whitelist
            if (assetIndex[_asset] >= whitelistedAssets.length) {
                revert AssetNotInList(_asset, whitelistedAssets.length);
            }
            
            // Move last element to deleted spot to maintain array structure
            address lastAsset = whitelistedAssets[whitelistedAssets.length - 1];
            uint256 indexToRemove = assetIndex[_asset];
            
            whitelistedAssets[indexToRemove] = lastAsset;
            assetIndex[lastAsset] = indexToRemove;
            
            whitelistedAssets.pop();
            delete assetIndex[_asset];
            delete tokenType[_asset];
            
            emit AssetWhitelistedRemoved(_asset);
        } else if (_allowed) {
            emit AssetWhitelisted(_asset, _tokenType, _allowed);
        }
    }
    
    /// @notice Batch whitelist assets
    /// @param _assets Array of asset addresses
    /// @param _tokenTypes Array of token types
    /// @param _allowed Array of allowed status
    function batchSetAssetWhitelist(
        address[] memory _assets,
        uint16[] memory _tokenTypes,
        bool[] memory _allowed
    ) external onlyOwner {
        if (_assets.length != _tokenTypes.length || _assets.length != _allowed.length) {
            revert ArrayLengthMismatch(_assets.length, _tokenTypes.length);
        }
        
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_assets[i] == address(0)) revert InvalidAsset(_assets[i]);
            this.setAssetWhitelist(_assets[i], _tokenTypes[i], _allowed[i]);
        }
    }
    
    /// @notice Get token type
    /// @param _asset Asset address
    function getTokenType(address _asset) public view returns (uint16) {
        return tokenType[_asset];
    }

    /// @notice Get all whitelisted assets
    function getWhitelistedAssets() external view returns (address[] memory) {
        return whitelistedAssets;
    }

    /// @notice Set the governance address
    /// @param _governanceAddress The address of the governance contract
    function setGovernanceAddress(address _governanceAddress) external onlyOwner {
        if (_governanceAddress == address(0)) revert InvalidGovernanceAddress(_governanceAddress);
        governance = _governanceAddress;
        emit GovernanceAddressSet(_governanceAddress);
    }

    /// @notice Set the treasury address
    /// @param _treasuryAddress The address of the treasury contract
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        if (_treasuryAddress == address(0)) revert InvalidTreasuryAddress(_treasuryAddress);
        treasury = _treasuryAddress;
        emit TreasuryAddressSet(_treasuryAddress);
    }

    /// @notice Set the admin address
    /// @param _adminAddress The address of the admin
    function setAdminAddress(address _adminAddress) external onlyOwner {
        if (_adminAddress == address(0)) revert InvalidAdminAddress(_adminAddress);
        admin = _adminAddress;
        emit AdminAddressSet(_adminAddress);
    }

    /// @notice Update vault fees (factory owner only)
    /// @param _vault Vault address
    /// @param _managerFee New manager management fee (basis points, 0-200)
    /// @param _withdrawalFee New withdrawal fee (basis points, 0-100)
    function updateVaultFees(
        address _vault,
        uint256 _managerFee,
        uint256 _withdrawalFee
    ) external onlyOwner {
        if (!isVault[_vault]) revert NotAVault(_vault);
        
        // Validate fees using new structure
        if (_managerFee > 200) revert ManagementFeeExceedsMax(_managerFee, 200);
        if (_withdrawalFee > 100) revert WithdrawalFeeExceedsMax(_withdrawalFee, 100);
        
        IVault(_vault).updateFees(_managerFee, _withdrawalFee);
    }

    /// @notice Return the address of the asset handler
    /// @return Address of the asset handler
    function getAssetHandler() external view returns (address) {
        return _assetHandler;
    }

    /// @notice Set the asset handler address
    /// @param assetHandler The address of the asset handler
    function setAssetHandler(address assetHandler) external onlyOwner {
        if (assetHandler == address(0)) revert InvalidAssetHandler(assetHandler);
        _assetHandler = assetHandler;
        emit SetAssetHandler(assetHandler);
    }

    /// @notice Set maximum supported asset count
    /// @param count The maximum supported asset count
    function setMaximumSupportedAssetCount(uint256 count) external onlyOwner {
        _maximumSupportedAssetCount = count;
    }

    /// @notice Get maximum supported asset count
    /// @return The maximum supported asset count
    function getMaximumSupportedAssetCount() external view returns (uint256) {
        return _maximumSupportedAssetCount;
    }

    /// @notice Return boolean if the asset is supported (checks price feed)
    /// @return True if asset has a price feed
    function isValidAsset(address asset) public view returns (bool) {
        return IAssetHandler(_assetHandler).priceAggregators(asset) != address(0);
    }

    /// @notice Return the latest price of a given asset from price feed
    /// @param asset The address of the asset
    /// @return price The latest price of a given asset in USD
    function getAssetPrice(address asset) external view returns (uint256 price) {
        return IAssetHandler(_assetHandler).getUSDPrice(asset);
    }

    /// @notice Return type of the asset
    /// @param asset The address of the asset
    /// @return assetType The type of the asset
    function getAssetType(address asset) external view override(IHasAssetInfo, IVaultFactory) returns (uint16 assetType) {
        assetType = IAssetHandler(_assetHandler).assetTypes(asset);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Update vault implementation
    /// @param _newImplementation New implementation address
    function updateVaultImplementation(address _newImplementation) external onlyOwner {
        if (_newImplementation == address(0)) revert InvalidImplementation(_newImplementation);
        
        address oldImplementation = vaultImplementation;
        vaultImplementation = _newImplementation;
        implementationVersion++;
        
        emit VaultImplementationUpdated(oldImplementation, _newImplementation);
    }
    
    /// @notice Upgrade a specific vault
    /// @param _vault Vault address
    /// @param _newImplementation New implementation address (optional, uses current if not provided)
    function upgradeVault(address _vault, address _newImplementation) external onlyOwner {
        if (!isVault[_vault]) revert NotAVault(_vault);
        
        address implementationToUse = _newImplementation != address(0) ? 
            _newImplementation : vaultImplementation;
            
        ProxyAdmin(proxyAdmin).upgradeAndCall(
            ITransparentUpgradeableProxy(_vault),
            implementationToUse,
            ""
        );
        
        emit VaultUpgraded(_vault, implementationToUse);
    }

    /// @notice Batch upgrade multiple vaults
    /// @param _vaults Array of vault addresses
    /// @param _newImplementation New implementation address (optional)
    function batchUpgradeVaults(
        address[] memory _vaults, 
        address _newImplementation
    ) external onlyOwner {
        address implementationToUse = _newImplementation != address(0) ? 
            _newImplementation : vaultImplementation;
            
        for (uint256 i = 0; i < _vaults.length; i++) {
            if (!isVault[_vaults[i]]) revert NotAVault(_vaults[i]);
            
            ProxyAdmin(proxyAdmin).upgradeAndCall(
                ITransparentUpgradeableProxy(_vaults[i]),
                implementationToUse,
                ""
            );
            
            emit VaultUpgraded(_vaults[i], implementationToUse);
        }
    }
    
    /// @notice Set factory settings
    /// @param _maxCapacityLimit Maximum capacity limit (in 18 decimals, e.g., 10M = 10000000 * 1e18)
    /// @param _minCapacityLimit Minimum capacity limit (in 18 decimals, e.g., 1K = 1000 * 1e18)
    /// @param _creationFee Creation fee in native token
    function setFactorySettings(
        uint256 _maxCapacityLimit,
        uint256 _minCapacityLimit,
        uint256 _creationFee
    ) external onlyOwner {
        if (_maxCapacityLimit <= _minCapacityLimit) revert InvalidLimits(_minCapacityLimit, _maxCapacityLimit);
        
        maxCapacityLimit = _maxCapacityLimit;
        minCapacityLimit = _minCapacityLimit;
        creationFee = _creationFee;
        
        emit FactorySettingsUpdated(_maxCapacityLimit, _minCapacityLimit, _creationFee);
    }
    
    /// @notice Set capacity limits using asset-specific values (for easy configuration)
    /// @param _maxCapacityAmount Maximum capacity amount (in asset units, e.g., 10000000 for 10M)
    /// @param _minCapacityAmount Minimum capacity amount (in asset units, e.g., 1000 for 1K)
    /// @param _creationFee Creation fee in native token
    /// @dev This function converts asset amounts to 18-decimal format for internal storage
    function setFactorySettingsInAssetUnits(
        uint256 _maxCapacityAmount,
        uint256 _minCapacityAmount,
        uint256 _creationFee
    ) external onlyOwner {
        // Convert to 18-decimal format for internal storage
        // Example: 10M units -> 10M * 1e18
        uint256 maxCapacityLimit18 = _maxCapacityAmount * 1e18;
        uint256 minCapacityLimit18 = _minCapacityAmount * 1e18;
        
        if (maxCapacityLimit18 <= minCapacityLimit18) revert InvalidLimits(minCapacityLimit18, maxCapacityLimit18);
        
        maxCapacityLimit = maxCapacityLimit18;
        minCapacityLimit = minCapacityLimit18;
        creationFee = _creationFee;
        
        emit FactorySettingsUpdated(maxCapacityLimit18, minCapacityLimit18, _creationFee);
    }
    
    /// @notice Get adjusted capacity limits for a specific asset
    /// @param underlyingAsset The underlying asset address
    /// @return adjustedMaxLimit Max capacity limit adjusted for asset decimals
    /// @return adjustedMinLimit Min capacity limit adjusted for asset decimals
    function getAdjustedCapacityLimits(address underlyingAsset) external view returns (uint256 adjustedMaxLimit, uint256 adjustedMinLimit) {
        uint8 decimals = IERC20Metadata(underlyingAsset).decimals();
        adjustedMaxLimit = _getAdjustedCapacityLimit(maxCapacityLimit, decimals);
        adjustedMinLimit = _getAdjustedCapacityLimit(minCapacityLimit, decimals);
    }
    
    /// @notice Emergency pause factory
    function pause() external onlyOwner {
        _pause();
    }
    
    /// @notice Unpause factory
    function unpause() external onlyOwner {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                            GUARD MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Add underlying asset (can be used as vault base asset)
    /// @param _asset Asset address (address(0) for native ETH)
    /// @param _tokenType Token type for classification
    function addUnderlyingAsset(
        address _asset,
        uint16 _tokenType
    ) external onlyOwner {
        // Allow address(0) for native ETH only if tokenType is NativeTokenType (2)
        if (_asset == address(0) && _tokenType != 2) revert InvalidAssetForType(_asset, _tokenType);
        if (underlyingAssetAllowed[_asset]) revert AssetAlreadyAdded(_asset);
        
        // Add to underlying assets
        underlyingAssetAllowed[_asset] = true;
        underlyingAssets.push(_asset);
        underlyingAssetIndex[_asset] = underlyingAssets.length - 1;
        tokenType[_asset] = _tokenType;
        
        emit UnderlyingAssetAdded(_asset, _tokenType);
    }

    /// @notice Add whitelisted asset (can be held in vaults)
    /// @param _asset Asset address (address(0) for native ETH)
    /// @param _tokenType Token type for classification
    function addWhitelistedAsset(
        address _asset,
        uint16 _tokenType
    ) external onlyOwner {
        // Allow address(0) for native ETH only if tokenType is NativeTokenType (2)
        if (_asset == address(0) && _tokenType != 2) revert InvalidAssetForType(_asset, _tokenType);
        if (assetWhitelisted[_asset]) revert AssetAlreadyAdded(_asset);
        
        // Add to whitelist
        assetWhitelisted[_asset] = true;
        whitelistedAssets.push(_asset);
        assetIndex[_asset] = whitelistedAssets.length - 1;
        tokenType[_asset] = _tokenType;
        
        emit AssetWhitelisted(_asset, _tokenType, true);
    }
    
    /// @notice Remove underlying asset
    /// @param _asset Asset address
    function removeUnderlyingAsset(address _asset) external onlyOwner {
        if (_asset == address(0)) revert InvalidAsset(_asset);
        if (!underlyingAssetAllowed[_asset]) revert AssetNotInList(_asset, underlyingAssets.length);
        
        // Remove from underlying assets
        underlyingAssetAllowed[_asset] = false;
        
        if (underlyingAssetIndex[_asset] >= underlyingAssets.length) revert AssetNotInList(_asset, underlyingAssets.length);
        
        // Move last element to deleted spot
        address lastAsset = underlyingAssets[underlyingAssets.length - 1];
        uint256 indexToRemove = underlyingAssetIndex[_asset];
        
        underlyingAssets[indexToRemove] = lastAsset;
        underlyingAssetIndex[lastAsset] = indexToRemove;
        
        underlyingAssets.pop();
        delete underlyingAssetIndex[_asset];
        delete tokenType[_asset];
        
        emit UnderlyingAssetRemoved(_asset);
    }

    /// @notice Remove whitelisted asset
    /// @param _asset Asset address
    function removeWhitelistedAsset(address _asset) external onlyOwner {
        if (_asset == address(0)) revert InvalidAsset(_asset);
        if (!assetWhitelisted[_asset]) revert AssetNotWhitelisted(_asset);
        
        // Remove from whitelist
        assetWhitelisted[_asset] = false;
        
        if (assetIndex[_asset] >= whitelistedAssets.length) revert AssetNotInList(_asset, whitelistedAssets.length);
        
        // Move last element to deleted spot
        address lastAsset = whitelistedAssets[whitelistedAssets.length - 1];
        uint256 indexToRemove = assetIndex[_asset];
        
        whitelistedAssets[indexToRemove] = lastAsset;
        assetIndex[lastAsset] = indexToRemove;
        
        whitelistedAssets.pop();
        delete assetIndex[_asset];
        delete tokenType[_asset];
        
        emit AssetWhitelistedRemoved(_asset);
    }

    /// @notice Get all underlying assets
    /// @return Array of underlying asset addresses
    function getUnderlyingAssets() external view returns (address[] memory) {
        return underlyingAssets;
    }

    /// @notice Get underlying asset count
    /// @return Number of underlying assets
    function getUnderlyingAssetCount() external view returns (uint256) {
        return underlyingAssets.length;
    }

    /// @notice Get whitelisted asset count
    /// @return Number of whitelisted assets
    function getWhitelistedAssetCount() external view returns (uint256) {
        return whitelistedAssets.length;
    }

    /// @notice Check if asset is allowed as underlying
    /// @param _asset Asset address
    /// @return True if asset can be used as underlying
    function isUnderlyingAssetAllowed(address _asset) external view returns (bool) {
        return underlyingAssetAllowed[_asset];
    }

    /// @notice Check if asset is whitelisted for vaults
    /// @param _asset Asset address  
    /// @return True if asset can be held in vaults
    function isAssetWhitelisted(address _asset) external view returns (bool) {
        return assetWhitelisted[_asset];
    }
    
    /// @notice Set governance address mapping
    /// @param _name Name identifier
    /// @param _address Address to map
    function setGovernanceAddress(bytes32 _name, address _address) external onlyOwner {
        if (_address == address(0)) revert InvalidAddress(_address, "Governance address");
        governanceAddresses[_name] = _address;
        emit GovernanceAddressMapped(_name, _address);
    }

    /*//////////////////////////////////////////////////////////////
                        GUARD INFO IMPLEMENTATION
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Get address of the transaction guards
    /// @param externalContract The address of the external contract
    /// @return guard Return the address of the transaction guard
    /// @return platform Platform name or guard name
    function getGuard(address externalContract) external view override returns (address guard, string memory platform) {
        guard = IGovernance(governance).contractGuards(externalContract);
        if (guard == address(0)) {
            guard = getAssetGuard(externalContract);
            platform = ""; // Asset guard name not stored in factory
        } else {
            platform = IPlatformGuard(guard).platformName();
        }
    }
    
    /// @notice Get address of the asset guard
    /// @param externalAsset The address of the external asset
    /// @return guard Address of the asset guard
    function getAssetGuard(address externalAsset) public view override returns (address guard) {
        uint16 assetType = getTokenType(externalAsset);
        IGovernance governanceContract = IGovernance(governance);
        guard = governanceContract.assetGuards(assetType);
    }
    
    /// @notice Get governance address mapping (IHasGuardInfo implementation)
    /// @param _name Name identifier
    /// @return Mapped address
    function getAddress(bytes32 _name) external view override returns (address) {
        return governanceAddresses[_name];
    }

    /// @notice Check if asset has a guard (via governance)
    /// @param _asset Asset address
    /// @return True if asset has a guard
    function hasGuard(address _asset) external view returns (bool) {
        return getAssetGuard(_asset) != address(0);
    }

    /// @notice Get all whitelisted assets with their types
    /// @return assets Array of asset addresses
    /// @return types Array of corresponding asset types
    function getAssetsWithTypes() external view returns (address[] memory assets, uint16[] memory types) {
        assets = new address[](whitelistedAssets.length);
        types = new uint16[](whitelistedAssets.length);
        
        for (uint256 i = 0; i < whitelistedAssets.length; i++) {
            assets[i] = whitelistedAssets[i];
            types[i] = tokenType[whitelistedAssets[i]];
        }
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Get all deployed vaults
    function getDeployedVaults() external view returns (address[] memory) {
        return deployedVaults;
    }

    /// @notice Get number of deployed vaults
    function getVaultCount() external view returns (uint256) {
        return deployedVaults.length;
    }
    
    /// @notice Get vaults by manager (gas optimized single-pass)
    /// @param _manager Manager address
    function getVaultsByManager(address _manager) external view returns (address[] memory) {
        uint256 vaultsLength = deployedVaults.length;
        

        address[] memory tempResult = new address[](vaultsLength);
        uint256 count = 0;
        
  
        for (uint256 i = 0; i < vaultsLength;) {
            address vault = deployedVaults[i];
            if (vaultManager[vault] == _manager) {
                tempResult[count] = vault;
                unchecked { ++count; }
            }
            unchecked { ++i; }
        }
        

        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count;) {
            result[i] = tempResult[i];
            unchecked { ++i; }
        }
        
        return result;
    }
    
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
    ) {
        if (!isVault[_vault]) revert NotAVault(_vault);
        
        IVault vault = IVault(_vault);
        manager = vaultManager[_vault];
        underlyingAsset = vault.asset();
        totalAssets = vault.totalAssets();
        totalSupply = vault.totalSupply();
        maxCapacity = vault.maxCapacity();
        isPaused = PausableUpgradeable(address(vault)).paused();
        
        sharePrice = totalSupply > 0 ? (totalAssets * 1e18) / totalSupply : 1e18;
    }

    /// @notice Get detailed vault info using vault's own function
    /// @param _vault Vault address
    function getDetailedVaultInfo(address _vault) external view returns (
        address underlyingAsset,
        uint256 totalShares,
        uint256 totalAssetsAmount,
        uint256 sharePrice,
        uint256 maxCap,
        uint256 minDeposit
    ) {
        if (!isVault[_vault]) revert NotAVault(_vault);
        
        return IVault(_vault).getVaultInfo();
    }
    
    /// @notice Get factory stats
    function getFactoryStats() external view returns (
        uint256 totalVaults,
        uint256 totalValueLocked,
        uint256 whitelistedAssetsCount,
        address[] memory topVaultsByTVL
    ) {
        totalVaults = deployedVaults.length;
        totalValueLocked = 0;
        whitelistedAssetsCount = whitelistedAssets.length;
        
        // Calculate total value locked
        for (uint256 i = 0; i < deployedVaults.length; i++) {
            try IVault(deployedVaults[i]).totalAssets() returns (uint256 assets) {
                totalValueLocked += assets;
            } catch {
                // Skip if vault call fails
            }
        }
        
        // For simplicity, return all vaults as "top" vaults
        // In a real implementation, you'd sort by TVL
        topVaultsByTVL = deployedVaults;
    }
    
    /// @notice Check if address is a vault created by this factory
    /// @param _vault Address to check
    function isValidVault(address _vault) external view returns (bool) {
        return isVault[_vault];
    }

    /// @notice Get vault manager
    /// @param _vault Vault address
    function getVaultManager(address _vault) external view returns (address) {
        return vaultManager[_vault];
    }

     /// @notice Add an address to the whitelist
     /// @param _underlyingAsset The address to add to whitelist
     function addUnderlyingAssetWhitelist(address _underlyingAsset) external onlyOwner {
         underlyingAssetAllowed[_underlyingAsset] = true;
     }

     /// @notice Remove an address from the whitelist
     /// @param _underlyingAsset The address to remove from whitelist
     function removeUnderlyingAssetWhitelist(address _underlyingAsset) external onlyOwner {
         underlyingAssetAllowed[_underlyingAsset] = false;
     }



     /// @notice Set the vault storage version
     /// @param _vaultStorageVersion The vault storage version
     function setVaultStorageVersion(uint256 _vaultStorageVersion) external onlyOwner {
         if (_vaultStorageVersion <= vaultStorageVersion) revert VersionTooLow(vaultStorageVersion, _vaultStorageVersion);
         vaultStorageVersion = _vaultStorageVersion;
         emit SetVaultStorageVersion(_vaultStorageVersion);
     }

     /// @notice Get implementation version
     function version() external pure returns (string memory) {
         return "1.1.0";
     }

    /*//////////////////////////////////////////////////////////////
                            EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emergency asset recovery (only owner)
    /// @param _asset Asset address (0x0 for native token)
    /// @param _amount Amount to recover
    function emergencyRecoverAsset(address _asset, uint256 _amount) external onlyOwner {
        if (_asset == address(0)) {
            // Native token
            (bool success, ) = treasury.call{value: _amount}("");
            if (!success) revert NativeTokenRecoveryFailed(treasury, _amount);
        } else {
            // ERC20 token
            IERC20(_asset).transfer(treasury, _amount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            OVERRIDE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Override owner function to match interface
    function owner() public view override(OwnableUpgradeable, IVaultFactory) returns (address) {
        return super.owner();
    }

    /// @notice Override paused function to match interface  
    function paused() public view override(PausableUpgradeable, IVaultFactory) returns (bool) {
        return super.paused();
    }
} 
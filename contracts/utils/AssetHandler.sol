
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IAggregatorV3Interface.sol";
import "../interfaces/IAssetHandler.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

// Price feed errors
error PriceAggregatorNotFound(address asset);
error ChainlinkPriceExpired(address asset, uint256 lastUpdated, uint256 timeout);
error PriceNotAvailable(address asset, uint256 price);
error PriceGetFailed(address asset, address aggregator);

// Asset validation errors
error InvalidAssetAddress(address asset);
error InvalidAssetForType(address asset, uint16 assetType);
error InvalidAggregatorAddress(address aggregator, address asset);

/// @title AssetHandler
/// @notice Contract for handling asset price feeds
contract AssetHandler is OwnableUpgradeable, IAssetHandler {

  uint256 public chainlinkTimeout; // Chainlink oracle timeout period

  // Asset Mappings
  mapping(address => uint16) public override assetTypes; // for asset types refer to header comment
  mapping(address => address) public override priceAggregators;

  event SetChainlinkTimeout(uint256 _chainlinkTimeout);

  /// @notice initialisation for the contract
  /// @param assets An array of assets to initialise
  function initialize(Asset[] memory assets) external initializer {
    __Ownable_init(msg.sender);

    chainlinkTimeout = 90000; // 25 hours
    addAssets(assets);
  }

  /* ========== VIEWS ========== */

  /**
   * @notice Currenly only use chainlink price feed.
   * @dev Calculate the USD price of a given asset.
   * @param asset the asset address
   * @return price Returns the latest price of a given asset (decimal: 18)
   */
  function getUSDPrice(address asset) external view override returns (uint256 price) {
    address aggregator = priceAggregators[asset];

    if (aggregator == address(0)) revert PriceAggregatorNotFound(asset);

    try IAggregatorV3Interface(aggregator).latestRoundData() returns (
      uint80,
      int256 _price,
      uint256,
      uint256 updatedAt,
      uint80
    ) {
      // check chainlink price updated within 25 hours
      if (updatedAt + chainlinkTimeout < block.timestamp) revert ChainlinkPriceExpired(asset, updatedAt, chainlinkTimeout);

      if (_price > 0) {
        price = uint256(_price) * 10**10; // convert Chainlink decimals 8 -> 18
      }
    } catch {
      revert PriceGetFailed(asset, aggregator);
    }

    if (price <= 0) revert PriceNotAvailable(asset, price);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /* ---------- From Owner ---------- */

  /// @notice Setting the timeout for the Chainlink price feed
  /// @param newTimeoutPeriod A new time in seconds for the timeout
  function setChainlinkTimeout(uint256 newTimeoutPeriod) external onlyOwner {
    chainlinkTimeout = newTimeoutPeriod;
    emit SetChainlinkTimeout(newTimeoutPeriod);
  }

  /// @notice Add valid asset with price aggregator
  /// @param asset Address of the asset to add
  /// @param assetType Type of the asset
  /// @param aggregator Address of the aggregator
  function addAsset(
    address asset,
    uint16 assetType,
    address aggregator
  ) public override onlyOwner {
     // Allow address(0) for native ETH only if tokenType is NativeTokenType (2)
    if (asset == address(0) && assetType != 2) revert InvalidAssetForType(asset, assetType);
    if (aggregator == address(0)) revert InvalidAggregatorAddress(aggregator, asset);

    assetTypes[asset] = assetType;
    priceAggregators[asset] = aggregator;

    emit AddedAsset(asset, assetType, aggregator);
  }

  /// @notice Add valid assets with price aggregator
  /// @param assets An array of assets to add
  function addAssets(Asset[] memory assets) public override onlyOwner {
    for (uint8 i = 0; i < assets.length; i++) {
      addAsset(assets[i].asset, assets[i].assetType, assets[i].aggregator);
    }
  }

  /// @notice Remove valid asset
  /// @param asset Address of the asset to remove
  function removeAsset(address asset) external override onlyOwner {
    assetTypes[asset] = 0;
    priceAggregators[asset] = address(0);

    emit RemovedAsset(asset);
  }

  uint256[50] private __gap;
}
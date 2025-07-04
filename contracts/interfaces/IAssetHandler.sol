// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

/// @title IAssetHandler
/// @notice Interface for IAssetHandler contract
interface IAssetHandler {
  event AddedAsset(address asset, uint16 assetType, address aggregator);
  event RemovedAsset(address asset);

  struct Asset {
    address asset;
    uint16 assetType;
    address aggregator;
  }

  function addAsset(address asset, uint16 assetType, address aggregator) external;

  function addAssets(Asset[] memory assets) external;

  function removeAsset(address asset) external;

  function priceAggregators(address asset) external view returns (address);

  function assetTypes(address asset) external view returns (uint16);

  function getUSDPrice(address asset) external view returns (uint256);
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title IHasSupportedAsset
/// @notice Interface for IHasSupportedAsset contract
interface IHasSupportedAsset {
  function getSupportedAssets() external view returns (address[] memory);
  function isSupportedAsset(address asset) external view returns (bool);
  function getAssetType(address asset) external view returns (uint16);
}

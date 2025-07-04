// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title IHasAssetInfo
/// @notice Interface for IHasAssetInfo contract    
interface IHasAssetInfo {
  function isValidAsset(address asset) external view returns (bool);

  function getAssetPrice(address asset) external view returns (uint256);

  function getAssetType(address asset) external view returns (uint16);

  function getMaximumSupportedAssetCount() external view returns (uint256);
}
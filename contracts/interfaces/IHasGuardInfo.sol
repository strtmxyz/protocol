// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title IHasGuardInfo
/// @notice Interface for IHasGuardInfo contract
interface IHasGuardInfo {
  function getGuard(address externalContract) external view returns (address, string memory);
  // Get asset guard
  function getAssetGuard(address externalAsset) external view returns (address);

  // Get mapped addresses from Governance
  function getAddress(bytes32 name) external view returns (address);
}

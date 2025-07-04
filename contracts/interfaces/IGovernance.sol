// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title IGovernance
/// @notice Interface for Governance contract
interface IGovernance {
  function contractGuards(address target) external view returns (address guard);

  function assetGuards(uint16 assetType) external view returns (address guard);

  function nameToDestination(bytes32 name) external view returns (address);
}
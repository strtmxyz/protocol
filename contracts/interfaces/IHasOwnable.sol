// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title IHasOwnable
/// @notice Interface for IHasOwnable contract
interface IHasOwnable {
  function owner() external view returns (address);
}

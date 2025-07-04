// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title IHasPausable
/// @notice Interface for IHasPausable contract 
interface IHasPausable {
  function isPaused() external view returns (bool);
}
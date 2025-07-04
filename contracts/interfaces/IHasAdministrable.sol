// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title IHasAdministrable
/// @notice Interface for IHasAdministrable contract
interface IHasAdministrable {
  /// @notice Event emitted when admin is changed
  /// @param admin The new admin address
  event AdminChanged(address indexed admin);

  /// @notice Get the admin address
  /// @return The admin address
  function admin() external view returns (address);
}

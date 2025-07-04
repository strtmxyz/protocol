//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title IWETH
/// @notice Interface for WETH contract     
/// @dev This interface is used to interact with the WETH contract

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}
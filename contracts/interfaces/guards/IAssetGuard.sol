// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAssetGuard {
  event ERC20Approval(address vault, address token, address spender, uint256 amount);
  event ERC721Approval(address vault, address token, address spender, uint256 tokenId);
  event WrapNativeToken(address vault, address token, uint256 amount);
  event UnwrapNativeToken(address vault, address token, uint256 amount);
  function getBalance(address vault, address asset) external view returns (uint256 balance);
  function getDecimals(address asset) external view returns (uint8 decimals);
  function calcValue(address vault, address asset, uint256 balance) external view returns (uint256 value);
}

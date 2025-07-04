// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IGuard.sol";

interface IPlatformGuard is IGuard {
  event UnwrapNativeToken(address vault, address dex, uint256 amountMinimum);
  event ExchangeFrom(address vault, address dex, address sourceAsset, uint256 sourceAmount, address dstAsset);
  event ExchangeTo(address vault, address dex, address sourceAsset, address dstAsset, uint256 dstAmount);
  event AddLiquidity(address vault, address dex, address pair, bytes params);
  event RemoveLiquidity(address vault, address dex, address pair, bytes params);
  // Vertexprotocol
  event VertexDeposit(
    address vault,
    address endpoint,
    uint256 amount
  );
  event VertexSlowMode(
    address vault,
    address endpoint,
    uint256 deadline
  );

  function platformName() external view returns (string memory);
}

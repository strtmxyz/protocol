// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../../utils/TxDataUtils.sol";
import "../../interfaces/guards/IGuard.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/IHasGuardInfo.sol";
import "../../interfaces/guards/IAssetGuard.sol";
import "../../interfaces/IHasAssetInfo.sol";
import "../../interfaces/external/pancakeswap/IPancakeV2Pair.sol";
import "./ERC20Guard.sol";

/// @title PancakeSwap V2 LP Token Guard
/// @notice Asset guard for PancakeSwap V2 LP tokens
/// @dev Calculates LP token value based on underlying reserves
contract ERC20PancakeLPGuard is ERC20Guard {
  
  function initialize(address _WETH) public override initializer {
    super.initialize(_WETH);
  }

  /// @notice Calculate the USD value of LP token balance
  /// @param vault The vault address
  /// @param asset The LP token address  
  /// @param balance The LP token balance
  /// @return value The total USD value of the LP position
  function calcValue(address vault, address asset, uint256 balance) external view override returns (uint256 value) {
    address factory = IVault(vault).factory();
    IPancakeV2Pair pair = IPancakeV2Pair(asset);
    
    // Get reserves and total supply
    (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
    uint256 totalSupply = pair.totalSupply();
    
    // Calculate proportional share of reserves
    uint256 amount0 = (reserve0 * balance) / totalSupply;
    uint256 amount1 = (reserve1 * balance) / totalSupply;
    
    // Calculate total value as sum of both token values
    value = _assetValue(factory, pair.token0(), amount0) + _assetValue(factory, pair.token1(), amount1);
  }
}

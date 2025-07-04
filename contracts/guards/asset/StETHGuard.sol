// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Guard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IHasAssetInfo.sol";

// Lido stETH contract interface
interface IStETH {
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
    function getSharesByPooledEth(uint256 _pooledEthAmount) external view returns (uint256);
    function getTotalShares() external view returns (uint256);
    function getTotalPooledEther() external view returns (uint256);
}

/// @title Lido stETH Asset Guard
/// @notice Specialized guard for Lido staked ETH tokens
/// @dev Handles the conversion between stETH tokens and their underlying ETH value
contract StETHGuard is ERC20Guard {
    
    address public constant STETH_ADDRESS = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84; // Mainnet stETH
    address public constant ETH_ADDRESS = 0x0000000000000000000000000000000000000000; // ETH representation
    
    /// @notice Calculate value for stETH tokens
    /// @dev Converts stETH balance to underlying ETH value, then to USD
    function _calculateRepresentativeTokenValue(
        address factory,
        address asset,
        uint256 balance
    ) internal view override returns (uint256 value) {
        // Only handle stETH, fallback to parent for other assets
        if (asset != STETH_ADDRESS) {
            return super._calculateRepresentativeTokenValue(factory, asset, balance);
        }
        
        // Get the underlying ETH amount for the stETH balance
        uint256 underlyingETHAmount = _getUnderlyingETHAmount(balance);
        
        // Get ETH price in USD
        uint256 ethPriceInUsd = IHasAssetInfo(factory).getAssetPrice(ETH_ADDRESS);
        
        // Calculate total USD value: ETH amount * ETH price
        value = (underlyingETHAmount * ethPriceInUsd) / (10**18); // ETH has 18 decimals
        
        return value;
    }
    
    /// @notice Get underlying ETH amount for stETH balance
    /// @param stETHBalance Balance of stETH tokens
    /// @return ethAmount Underlying ETH amount
    function _getUnderlyingETHAmount(uint256 stETHBalance) internal view returns (uint256 ethAmount) {
        IStETH stETH = IStETH(STETH_ADDRESS);
        
        try stETH.getPooledEthByShares(stETHBalance) returns (uint256 pooledEth) {
            return pooledEth;
        } catch {
            // Fallback: use simple ratio calculation
            try stETH.getTotalShares() returns (uint256 totalShares) {
                try stETH.getTotalPooledEther() returns (uint256 totalPooledEther) {
                    if (totalShares > 0) {
                        return (stETHBalance * totalPooledEther) / totalShares;
                    }
                } catch {}
            } catch {}
            
            // Last resort: assume 1:1 ratio (not accurate but safe fallback)
            return stETHBalance;
        }
    }
    
    /// @notice Get balance of stETH (same as regular ERC20)
    /// @dev stETH balance represents shares, but this is handled in value calculation
    function getBalance(address vault, address asset) public view override returns (uint256 balance) {
        if (asset == STETH_ADDRESS) {
            return IERC20(asset).balanceOf(vault);
        }
        return super.getBalance(vault, asset);
    }
} 
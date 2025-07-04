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
import "../../interfaces/IWETH.sol";
import "../../interfaces/ITransactionTypes.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

// Asset validation errors
error UnsupportedAsset();
error UnsupportedSpenderApproval();

// Token amount validation errors
error PayableAmountMustBeZero();

/// @title ERC20 Asset Guard
contract ERC20Guard is TxDataUtils, IGuard, IAssetGuard, ITransactionTypes, Initializable
{
  address public WETH;
  function initialize(address _WETH) public virtual initializer {
    WETH = _WETH;
  }

  /// @notice Transaction guard for ERC20 assets
  /// @dev Parses the transaction data to ensure transaction is valid
  /// @param _vault Vault address
  /// @param _to Token address
  /// @param _data Transaction call data attempt by manager
  /// @return txType transaction type
  function txGuard(address _vault, address _to, bytes calldata _data)
    public virtual returns (uint16 txType)
  {
    bytes4 method = getMethod(_data);

    if (method == bytes4(keccak256("approve(address,uint256)"))) {
      address spender = convert32toAddress(getInput(_data, 0));
      uint256 amount = uint256(getInput(_data, 1));

      address factory = IVault(_vault).factory();

      // Check if asset is supported - try vault's method first, fallback to factory check
      bool isAssetSupported = false;
      try IHasSupportedAsset(_vault).isSupportedAsset(_to) returns (bool supported) {
        isAssetSupported = supported;
      } catch {
        // Fallback: check if asset is valid in factory for older vault versions
        isAssetSupported = IHasAssetInfo(factory).isValidAsset(_to);
      }
      if (!isAssetSupported) revert UnsupportedAsset();

      (address spenderGuard, ) = IHasGuardInfo(factory).getGuard(spender);
      if (spenderGuard == address(0) || spenderGuard == address(this)) revert UnsupportedSpenderApproval(); // checks that the spender is an approved address

      emit ERC20Approval(_vault, _to, spender, amount);

      txType = uint16(TransactionType.Approve);
    }
    else if(_to == WETH) {
      if (method == IWETH.withdraw.selector) {
        IHasSupportedAsset supportedAsset = IHasSupportedAsset(_vault);
        if (!supportedAsset.isSupportedAsset(_to)) revert UnsupportedAsset();
        if (!supportedAsset.isSupportedAsset(address(0))) revert UnsupportedAsset();

        uint256 amount = abi.decode(
          getParams(_data),
          (uint256)
        );
        emit UnwrapNativeToken(_vault, _to, amount);

        txType = uint16(TransactionType.UnwrapNativeToken);
      }
    }

    return txType;
  }

  function txGuard(address _vault, address _to, bytes calldata _data, uint256 _nativeTokenAmount)
    public virtual returns (uint16 txType)
  {
    bytes4 method = getMethod(_data);

    if (
      method == IWETH.deposit.selector
      && _to == WETH
      && _nativeTokenAmount > 0
    ) {
      IHasSupportedAsset supportedAsset = IHasSupportedAsset(_vault);
      if (!supportedAsset.isSupportedAsset(_to)) revert UnsupportedAsset();
      if (!supportedAsset.isSupportedAsset(address(0))) revert UnsupportedAsset();

      emit WrapNativeToken(_vault, WETH, _nativeTokenAmount);

      txType = uint16(TransactionType.WrapNativeToken);
    }
    else {
      if (_nativeTokenAmount != 0) revert PayableAmountMustBeZero();
      txType = txGuard(_vault, _to, _data);
    }


    return txType;
  }

  function getBalance(address vault, address asset) public view virtual override returns (uint256 balance) {
    balance = IERC20(asset).balanceOf(vault);
  }

  function getDecimals(address asset) external view virtual override returns (uint8 decimals) {
    decimals = IERC20Metadata(asset).decimals();
  }

  function calcValue(address vault, address asset, uint256 balance) external view virtual returns (uint256 value) {
    address factory = IVault(vault).factory();
    
    // For representative tokens, calculate the true underlying value
    // This method can be overridden in specialized guards for specific protocols
    value = _calculateRepresentativeTokenValue(factory, asset, balance);
  }

  function _assetValue(
    address factory,
    address token,
    uint256 amount
  ) internal view returns (uint256) {
    uint256 tokenPriceInUsd = IHasAssetInfo(factory).getAssetPrice(token);
    return tokenPriceInUsd * amount / (10**IERC20Metadata(token).decimals());
  }
  
  /// @notice Calculate value for representative tokens
  /// @dev This handles tokens that represent assets in other protocols
  /// @param factory Factory address for price feeds
  /// @param asset Representative token address
  /// @param balance Balance of representative token
  /// @return value True USD value of represented assets
  function _calculateRepresentativeTokenValue(
    address factory,
    address asset,
    uint256 balance
  ) internal view virtual returns (uint256 value) {
    // Default implementation: treat as regular ERC20 token
    // Specialized guards should override this for specific protocols
    
    // Examples of what specialized guards would implement:
    // 1. For stETH: balance * stETH_to_ETH_rate * ETH_price
    // 2. For LP tokens: (balance / totalSupply) * (reserve0_value + reserve1_value)
    // 3. For yield tokens: balance * exchangeRate * underlying_price
    // 4. For receipt tokens: balance * protocol_exchange_rate * underlying_value
    
    return _assetValue(factory, asset, balance);
  }


}

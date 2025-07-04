// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../interfaces/guards/IPlatformGuard.sol";
import "../../utils/TxDataUtils.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/ITransactionTypes.sol";
import "../../interfaces/external/vertexprotocol/IEndpoint.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

// Subaccount validation errors
error InvalidSubaccount();

// Product validation errors
error UnsupportedProductId();

// Transaction timing errors
error TransactionExpired();

// Method support errors
error UnsupportedVertexMethod();
error NativeTokenTransactionsNotSupported();

contract VertexPlatformGuard is TxDataUtils, IPlatformGuard, ITransactionTypes, Initializable {

    string public override platformName;

    function initialize() public initializer {
        platformName = "vertexprotocol";
    }

    function txGuard(address _vault, address _to, bytes memory _data)
        public 
        override 
        returns (uint16 txType)
    {
        bytes4 method = getMethod(_data);

        if (method == IEndpoint.depositCollateral.selector) {
            (bytes12 subaccountName, uint32 productId, uint128 amount) = abi.decode(
                getParams(_data),
                (bytes12, uint32, uint128)
            );

            // Verify subaccount name is one of the allowed values (bytes12)
            if (
                subaccountName != bytes12(bytes("default")) &&
                subaccountName != bytes12(bytes("default_1")) &&
                subaccountName != bytes12(bytes("default_2")) &&
                subaccountName != bytes12(bytes("default_3"))
            ) {
                revert InvalidSubaccount();
            }

            // Verify productId is 0 (USDC or similar supported asset)
            if (productId != 0) revert UnsupportedProductId();

            emit VertexDeposit(_vault, _to, amount);

            txType = uint16(TransactionType.VertexDepositCollateral);
        } else if (method == IEndpoint.submitSlowModeTransaction.selector) {
            bytes memory transaction = abi.decode(
                getParams(_data),
                (bytes)
            );

            // Decode deadline from transaction (simplified parsing)
            (uint256 deadline) = abi.decode(transaction, (uint256));

            // Check if deadline is valid
            if (block.timestamp > deadline) revert TransactionExpired();

            emit VertexSlowMode(_to, _vault, deadline);

            txType = uint16(TransactionType.VertexSubmitTransaction);
        } else {
            revert UnsupportedVertexMethod();
        }

        return txType;
    }

    function txGuard(address /*_vault*/, address /*_to*/, bytes memory /*_data*/, uint256 /*_nativeTokenAmount*/)
        public 
        pure
        override 
        returns (uint16)
    {
        revert NativeTokenTransactionsNotSupported();
    }
}
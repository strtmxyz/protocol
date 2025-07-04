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
import "../../interfaces/external/vertexprotocol/Clearinghouse.sol";

contract VertexAssetGuard is TxDataUtils, IGuard, IAssetGuard, Initializable {

    function initialize() public initializer {
    }

    function txGuard(address /*_vault*/, address /*_to*/, bytes calldata /*_data*/)
        public 
        pure 
        virtual 
        override 
        returns (uint16)
    {
        revert("VertexAssetGuard: Direct transaction guard not implemented");
    }

    function txGuard(address /*_vault*/, address /*_to*/, bytes calldata /*_data*/, uint256 /*_nativeTokenAmount*/)
        public 
        pure 
        virtual 
        override 
        returns (uint16)
    {
        revert("VertexAssetGuard: Payable transaction guard not implemented");
    }

    // Returns 1 if any subaccount has assets, 0 otherwise.
    function getBalance(address vault, address asset) public view virtual override returns (uint256 balance) {
        balance = hasAsset(vault, asset) ? 1 : 0;
    }

    // Decimals are 0 as value represents health.
    function getDecimals(address) external view virtual override returns (uint8 decimals) {
        decimals = 0;
    }

    /// @notice Internal helper function to get the subaccount suffixes array
    /// @return suffixes Array of subaccount suffixes used by the vault
    function _getSubaccountSuffixes() internal pure returns (bytes12[] memory) {
        bytes12[] memory suffixes = new bytes12[](4);
        suffixes[0] = bytes12(bytes("default"));
        suffixes[1] = bytes12(bytes("default_1"));
        suffixes[2] = bytes12(bytes("default_2"));
        suffixes[3] = bytes12(bytes("default_3"));
        return suffixes;
    }

    // Calculates the total positive health across all subaccounts for the vault.
    function calcValue(address vault, address asset, uint256) external view virtual override returns (uint256 value) {
        Clearinghouse clearinghouse = Clearinghouse(asset);
        value = 0;

        // Get suffixes from helper function
        bytes12[] memory suffixes = _getSubaccountSuffixes();

        for (uint i = 0; i < suffixes.length; i++) {
            bytes32 subaccountId = _generateSubaccountId(vault, suffixes[i]);
            int128 health = clearinghouse.getHealth(subaccountId, 2); // Assuming 2 for health check type

            if (health > 0) {
                value += uint256(int256(health)); // Sum positive health
            }
            // Note: Negative health is currently ignored in the total value calculation.
        }

        return value;
    }

    // Checks if the vault has non-zero health in any of its subaccounts for the given clearinghouse (asset).
    function hasAsset(address vault, address asset) internal view returns (bool) {
        Clearinghouse clearinghouse = Clearinghouse(asset);

        // Get suffixes from helper function
        bytes12[] memory suffixes = _getSubaccountSuffixes();

        for (uint i = 0; i < suffixes.length; i++) {
            bytes32 subaccountId = _generateSubaccountId(vault, suffixes[i]);
            int128 health = clearinghouse.getHealth(subaccountId, 2); // Assuming 2 for health check type

            // If any subaccount has non-zero health (positive or negative), the vault has assets.
            if (health != 0) {
                return true;
            }
        }
        // If loop completes, no subaccount has non-zero health.
        return false;
    }

    // Generates the bytes32 subaccount ID based on the vault address and a suffix (now bytes12).
    function _generateSubaccountId(address vault, bytes12 suffix) internal pure returns (bytes32) {
        // Convert address to bytes20
        bytes20 addr = bytes20(vault);
        
        // Combine address, suffix, and padding according to the expected format
        // Format: address (20 bytes) + suffix (12 bytes) = bytes32 (no additional padding needed)
        bytes memory combined = abi.encodePacked(addr, suffix);
        
        // Convert to bytes32
        return bytes32(combined);
    }

    // Public function to get the subaccount ID for a specific vault and suffix.
    function getSubaccountId(address vault, bytes12 suffix) public pure returns (bytes32) {
        return _generateSubaccountId(vault, suffix);
    }
} 
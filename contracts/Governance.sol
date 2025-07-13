// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IGovernance.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

// Address validation errors
error InvalidExtContractAddress(address extContract);
error InvalidGuardAddress(address guardAddress, string context);

/// @title Governance
/// @dev A contract with storage managed by governance
/// @notice This contract is used to manage the governance of the protocol

contract Governance is IGovernance, OwnableUpgradeable {
  event ContractGuardSet(address extContract, address guardAddress);
  event AssetGuardSet(uint16 assetType, address guardAddress);
  event AddressSet(bytes32 name, address destination);

  struct ContractName {
    bytes32 name;
    address destination;
  }

  // Transaction Guards
  mapping(address => address) public override contractGuards;
  mapping(uint16 => address) public override assetGuards;

  // Addresses

  // "aaveProtocolDataProviderV2": aave protocol data provider
  // "aaveProtocolDataProviderV3": aave protocol data provider
  // "swapRouter": swapRouter with uniswap v2 interface.
  // "weth": weth address which is used token swap
  mapping(bytes32 => address) public override nameToDestination;

  function initialize() public initializer {
    __Ownable_init(msg.sender);
  }

 /* ========== RESTRICTED FUNCTIONS ========== */

  // Transaction Guards

  /// @notice Maps an exernal contract to a guard which enables managers to use the contract
  /// @param extContract The third party contract to integrate
  /// @param guardAddress The protections for manager third party contract interaction
  function setContractGuard(address extContract, address guardAddress) external onlyOwner {
    _setContractGuard(extContract, guardAddress);
  }

  /// @notice Set contract guard internal call
  /// @param extContract The third party contract to integrate
  /// @param guardAddress The protections for manager third party contract interaction
  function _setContractGuard(address extContract, address guardAddress) internal {
    if (extContract == address(0)) revert InvalidExtContractAddress(extContract);
    if (guardAddress == address(0)) revert InvalidGuardAddress(guardAddress, "setContractGuard");

    contractGuards[extContract] = guardAddress;

    emit ContractGuardSet(extContract, guardAddress);
  }

  /// @notice Maps an asset type to an asset guard which allows managers to enable the asset
  /// @dev Asset types are defined in AssetHandler.sol
  /// @param assetType Asset type as defined in Asset Handler
  /// @param guardAddress The asset guard address that allows manager interaction
  function setAssetGuard(uint16 assetType, address guardAddress) external onlyOwner {
    _setAssetGuard(assetType, guardAddress);
  }

  /// @notice Set asset guard internal call
  /// @param assetType Asset type as defined in Asset Handler
  /// @param guardAddress The asset guard address that allows manager interaction
  function _setAssetGuard(uint16 assetType, address guardAddress) internal {
    if (guardAddress == address(0)) revert InvalidGuardAddress(guardAddress, "setAssetGuard");

    assetGuards[assetType] = guardAddress;

    emit AssetGuardSet(assetType, guardAddress);
  }

  // Addresses

  /// @notice Maps multiple contract names to destination addresses
  /// @dev This is a central source that can be used to reference third party contracts
  /// @param contractNames The contract names and addresses struct
  function setAddresses(ContractName[] calldata contractNames) external onlyOwner {
    for (uint256 i = 0; i < contractNames.length; i++) {
      bytes32 name = contractNames[i].name;
      address destination = contractNames[i].destination;
      nameToDestination[name] = destination;
      emit AddressSet(name, destination);
    }
  }
}
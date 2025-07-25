/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Contract,
  ContractFactory,
  ContractTransactionResponse,
  Interface,
} from "ethers";
import type {
  Signer,
  AddressLike,
  ContractDeployTransaction,
  ContractRunner,
} from "ethers";
import type { NonPayableOverrides } from "../../../../../common";
import type {
  ProxyAdmin,
  ProxyAdminInterface,
} from "../../../../../@openzeppelin/contracts/proxy/transparent/ProxyAdmin";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "initialOwner",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "OwnableInvalidOwner",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "OwnableUnauthorizedAccount",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "previousOwner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipTransferred",
    type: "event",
  },
  {
    inputs: [],
    name: "UPGRADE_INTERFACE_VERSION",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "renounceOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "transferOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "contract ITransparentUpgradeableProxy",
        name: "proxy",
        type: "address",
      },
      {
        internalType: "address",
        name: "implementation",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "upgradeAndCall",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60803460bc57601f61046338819003918201601f19168301916001600160401b0383118484101760c15780849260209460405283398101031260bc57516001600160a01b0381169081900360bc57801560a657600080546001600160a01b031981168317825560405192916001600160a01b03909116907f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09080a361038b90816100d88239f35b631e4fbdf760e01b600052600060045260246000fd5b600080fd5b634e487b7160e01b600052604160045260246000fdfe6080604052600436101561001257600080fd5b6000803560e01c8063715018a6146102735780638da5cb5b1461024c5780639623609d1461011d578063ad3cb1cc146100d05763f2fde38b1461005457600080fd5b346100cd5760203660031901126100cd576004356001600160a01b038116908190036100cb57610082610335565b80156100b75781546001600160a01b03198116821783556001600160a01b031660008051602061035f8339815191528380a380f35b631e4fbdf760e01b82526004829052602482fd5b505b80fd5b50346100cd57806003193601126100cd57506101196040516100f36040826102bb565b60058152640352e302e360dc1b60208201526040519182916020835260208301906102f4565b0390f35b5060603660031901126100cd576004356001600160a01b038116908190036100cb576024356001600160a01b0381169081900361022c576044356001600160401b03811161024857366023820112156102485760048101356001600160401b038111610234576040518593929091906101a0601f8301601f1916602001846102bb565b81835236602483830101116102305781859260246020930183860137830101526101c8610335565b833b1561022c576101fe93839260405180968194829363278f794360e11b845260048401526040602484015260448301906102f4565b039134905af1801561021f576102115780f35b61021a916102bb565b388180f35b50604051903d90823e3d90fd5b8280fd5b8480fd5b634e487b7160e01b85526041600452602485fd5b8380fd5b50346100cd57806003193601126100cd57546040516001600160a01b039091168152602090f35b50346100cd57806003193601126100cd5761028c610335565b80546001600160a01b03198116825581906001600160a01b031660008051602061035f8339815191528280a380f35b601f909101601f19168101906001600160401b038211908210176102de57604052565b634e487b7160e01b600052604160045260246000fd5b919082519283825260005b848110610320575050826000602080949584010152601f8019910116010190565b806020809284010151828286010152016102ff565b6000546001600160a01b0316330361034957565b63118cdaa760e01b6000523360045260246000fdfe8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0a164736f6c634300081b000a";

type ProxyAdminConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: ProxyAdminConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class ProxyAdmin__factory extends ContractFactory {
  constructor(...args: ProxyAdminConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override getDeployTransaction(
    initialOwner: AddressLike,
    overrides?: NonPayableOverrides & { from?: string }
  ): Promise<ContractDeployTransaction> {
    return super.getDeployTransaction(initialOwner, overrides || {});
  }
  override deploy(
    initialOwner: AddressLike,
    overrides?: NonPayableOverrides & { from?: string }
  ) {
    return super.deploy(initialOwner, overrides || {}) as Promise<
      ProxyAdmin & {
        deploymentTransaction(): ContractTransactionResponse;
      }
    >;
  }
  override connect(runner: ContractRunner | null): ProxyAdmin__factory {
    return super.connect(runner) as ProxyAdmin__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ProxyAdminInterface {
    return new Interface(_abi) as ProxyAdminInterface;
  }
  static connect(address: string, runner?: ContractRunner | null): ProxyAdmin {
    return new Contract(address, _abi, runner) as unknown as ProxyAdmin;
  }
}

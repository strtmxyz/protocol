/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Contract,
  ContractFactory,
  ContractTransactionResponse,
  Interface,
} from "ethers";
import type { Signer, ContractDeployTransaction, ContractRunner } from "ethers";
import type { NonPayableOverrides } from "../../../../common";
import type {
  ETHGuard,
  ETHGuardInterface,
} from "../../../../contracts/guards/asset/ETHGuard";

const _abi = [
  {
    inputs: [],
    name: "ETHAmountMustBeGreaterThanZero",
    type: "error",
  },
  {
    inputs: [],
    name: "ETHGuardOnlyHandlesNativeETH",
    type: "error",
  },
  {
    inputs: [],
    name: "ETHGuardOnlySupportsNativeETH",
    type: "error",
  },
  {
    inputs: [],
    name: "InputIsNotArray",
    type: "error",
  },
  {
    inputs: [],
    name: "InvalidArrayPosition",
    type: "error",
  },
  {
    inputs: [],
    name: "InvalidETHPrice",
    type: "error",
  },
  {
    inputs: [],
    name: "InvalidInitialization",
    type: "error",
  },
  {
    inputs: [],
    name: "InvalidOffset",
    type: "error",
  },
  {
    inputs: [],
    name: "InvalidTargetAddress",
    type: "error",
  },
  {
    inputs: [],
    name: "InvalidWETHAddress",
    type: "error",
  },
  {
    inputs: [],
    name: "NotInitializing",
    type: "error",
  },
  {
    inputs: [],
    name: "ReadingBytesOutOfBounds",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "vault",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "ERC20Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "vault",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "ERC721Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint64",
        name: "version",
        type: "uint64",
      },
    ],
    name: "Initialized",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "vault",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "UnwrapNativeToken",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "vault",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "token",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "WrapNativeToken",
    type: "event",
  },
  {
    inputs: [],
    name: "WETH",
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
    inputs: [
      {
        internalType: "address",
        name: "vault",
        type: "address",
      },
      {
        internalType: "address",
        name: "asset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "balance",
        type: "uint256",
      },
    ],
    name: "calcValue",
    outputs: [
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "data",
        type: "bytes32",
      },
    ],
    name: "convert32toAddress",
    outputs: [
      {
        internalType: "address",
        name: "o",
        type: "address",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
      {
        internalType: "uint8",
        name: "inputNum",
        type: "uint8",
      },
      {
        internalType: "uint8",
        name: "arrayIndex",
        type: "uint8",
      },
    ],
    name: "getArrayIndex",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
      {
        internalType: "uint8",
        name: "inputNum",
        type: "uint8",
      },
    ],
    name: "getArrayLast",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
      {
        internalType: "uint8",
        name: "inputNum",
        type: "uint8",
      },
    ],
    name: "getArrayLength",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "vault",
        type: "address",
      },
      {
        internalType: "address",
        name: "asset",
        type: "address",
      },
    ],
    name: "getBalance",
    outputs: [
      {
        internalType: "uint256",
        name: "balance",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
      {
        internalType: "uint8",
        name: "inputNum",
        type: "uint8",
      },
      {
        internalType: "uint256",
        name: "offset",
        type: "uint256",
      },
    ],
    name: "getBytes",
    outputs: [
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "asset",
        type: "address",
      },
    ],
    name: "getDecimals",
    outputs: [
      {
        internalType: "uint8",
        name: "decimals",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
      {
        internalType: "uint8",
        name: "inputNum",
        type: "uint8",
      },
    ],
    name: "getInput",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "getMethod",
    outputs: [
      {
        internalType: "bytes4",
        name: "",
        type: "bytes4",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "getParams",
    outputs: [
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_weth",
        type: "address",
      },
    ],
    name: "initialize",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
      {
        internalType: "uint256",
        name: "offset",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "length",
        type: "uint256",
      },
    ],
    name: "read32",
    outputs: [
      {
        internalType: "bytes32",
        name: "o",
        type: "bytes32",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
      {
        internalType: "uint256",
        name: "offset",
        type: "uint256",
      },
    ],
    name: "read4left",
    outputs: [
      {
        internalType: "bytes4",
        name: "o",
        type: "bytes4",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    name: "txGuard",
    outputs: [
      {
        internalType: "uint16",
        name: "",
        type: "uint16",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "_to",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
      {
        internalType: "uint256",
        name: "_nativeTokenAmount",
        type: "uint256",
      },
    ],
    name: "txGuard",
    outputs: [
      {
        internalType: "uint16",
        name: "txType",
        type: "uint16",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60808060405234601557610dd6908161001b8239f35b600080fdfe6080604052600436101561001257600080fd5b60003560e01c806309ff5c7d146101275780631053f952146101225780631d81e80f1461011d5780631eba307714610118578063293d80631461011357806341dc16c31461010e5780636179309d14610109578063689015131461010457806382f86acc146100ff578063998546e3146100fa578063ad5c4648146100f5578063bd125da4146100f0578063c3c6279f146100eb578063c4d66de8146100e6578063cf54aaa0146100e1578063d4fac45d146100dc5763db896b57146100d757600080fd5b610a92565b610a50565b610a1a565b6108eb565b6108aa565b61081d565b6107f4565b6107c3565b610791565b6106cf565b610649565b610560565b6104ee565b6104c7565b6103f2565b610304565b610220565b634e487b7160e01b600052604160045260246000fd5b601f909101601f19168101906001600160401b0382119082101761016557604052565b61012c565b81601f820112156101c0578035906001600160401b038211610165576040519261019e601f8401601f191660200185610142565b828452602083830101116101c057816000926020809301838601378301015290565b600080fd5b6024359060ff821682036101c057565b6044359060ff821682036101c057565b60406003198201126101c057600435906001600160401b0382116101c05761020f9160040161016a565b9060243560ff811681036101c05790565b346101c05761024161024d60ff610246610239366101e5565b949094610b19565b610b2e565b1682610be1565b9060048201918281116102a5576102648383610be1565b80156102aa578060051b9081046020036102a55760049101018092116102a5576102a19161029191610be1565b6040519081529081906020820190565b0390f35b610b03565b631754cda560e31b60005260046000fd5b91909160208152825180602083015260005b8181106102ee575060409293506000838284010152601f8019910116010190565b80602080928701015160408286010152016102cd565b346101c05760603660031901126101c0576004356001600160401b0381116101c05761033490369060040161016a565b61033c6101c5565b906044359160148310156103d1578260051b92808404602014901517156102a55761036b61024160ff92610b19565b168281018091116102a5576103809082610be1565b60048101918282116102a5576103bf6103ba856103b56103af6103a96102a1996103c599610b6a565b86610be1565b95610b40565b610b6a565b610b4e565b90610c7a565b604051918291826102bb565b62ed0ab960e11b60005260046000fd5b6001600160a01b038116036101c057565b346101c05760603660031901126101c05760043561040f816103e1565b6024359061041c826103e1565b604435916001600160a01b03166104b65760405163c45a015560e01b815290602090829060049082906001600160a01b03165afa9081156104b15760009161046c575b6102a16102918484610d07565b90506020813d6020116104a9575b8161048760209383610142565b810103126101c0576102a19161029191516104a1816103e1565b91509161045f565b3d915061047a565b610ba0565b63194928fd60e01b60005260046000fd5b346101c05760203660031901126101c0576040516004356001600160a01b03168152602090f35b346101c05760403660031901126101c0576004356001600160401b0381116101c05761051e90369060040161016a565b60243590805160048301908184116102a5571061054f57016020908101516040516001600160e01b03199091168152f35b631853ab7360e21b60005260046000fd5b346101c05760603660031901126101c0576004356001600160401b0381116101c05761059090369060040161016a565b6105986101c5565b6105b860ff6105b16102416105ab6101d5565b94610b19565b1683610be1565b90600482018092116102a5576105ce8284610be1565b9081156102aa5760ff168091111561060b5760010191826001116102a557610605610291926105ff6102a195610b77565b90610b6a565b90610be1565b633135ee2560e21b60005260046000fd5b9181601f840112156101c0578235916001600160401b0383116101c057602083818601950101116101c057565b346101c05760603660031901126101c0576106656004356103e1565b6106706024356103e1565b6044356001600160401b0381116101c05761068f90369060040161061c565b5050630f777b0360e41b60005260046000fd5b60206003198201126101c057600435906001600160401b0382116101c0576106cc9160040161016a565b90565b346101c0576106dd366106a2565b80519060031982018281116102a557610700816106f981610b5c565b1015610bfd565b6107178251610710836004610b6a565b1115610c3a565b8061073c575050506102a16040516000815260208101604052604051918291826102bb565b604051601f8216928301831560051b90810160040194919384010191908201600319015b80831061077e57508252601f01601f19166040526102a191506103c5565b8451835260209485019490920191610760565b346101c05760206107bb61024160ff6107b46107ac366101e5565b939093610b19565b1690610be1565b604051908152f35b346101c0576102416107dc60ff610246610239366101e5565b90600482018092116102a5576020916107bb91610be1565b346101c05760003660031901126101c0576000546040516001600160a01b039091168152602090f35b346101c05760803660031901126101c0576108396004356103e1565b602435610845816103e1565b6044356001600160401b0381116101c05761086490369060040161061c565b505060643515610899576001600160a01b0316156108885760405160018152602090f35b633c6924b360e21b60005260046000fd5b631920581b60e01b60005260046000fd5b346101c0576108b8366106a2565b600060048251106108dc576020828101516040516001600160e01b03199091168152f35b631853ab7360e21b8152600490fd5b346101c05760203660031901126101c057600435610908816103e1565b600080516020610daa833981519152549060ff604083901c1615916001600160401b031680159081610a12575b6001149081610a08575b1590816109ff575b506109ee57600080516020610daa83398151915280546001600160401b031916600117905561097a90826109c957610bac565b61098057005b600080516020610daa833981519152805460ff60401b19169055604051600181527fc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d290602090a1005b600080516020610daa833981519152805460ff60401b1916600160401b179055610bac565b63f92ee8a960e01b60005260046000fd5b90501538610947565b303b15915061093f565b839150610935565b346101c05760203660031901126101c057600435610a37816103e1565b6001600160a01b03166104b65760405160128152602090f35b346101c05760403660031901126101c057600435610a6d816103e1565b602435610a79816103e1565b6001600160a01b03166104b65760209031604051908152f35b346101c05760603660031901126101c0576004356001600160401b0381116101c057610ac290369060040161016a565b602435906044359060008151838501908186116102a557106108dc5750602092839101015190820380610af9575b50604051908152f35b60031b1c38610af0565b634e487b7160e01b600052601160045260246000fd5b60051b90611fe060e08316921682036102a557565b60ff60049116019060ff82116102a557565b90600482018092116102a557565b90602082018092116102a557565b90601f82018092116102a557565b919082018092116102a557565b908160051b91808304602014901517156102a557565b818102929181159184041417156102a557565b6040513d6000823e3d90fd5b6001600160a01b03168015610bd157600080546001600160a01b031916919091179055565b6212c43360e51b60005260046000fd5b90815160208201908183116102a5571061054f57016020015190565b15610c0457565b60405162461bcd60e51b815260206004820152600e60248201526d736c6963655f6f766572666c6f7760901b6044820152606490fd5b15610c4157565b60405162461bcd60e51b8152602060048201526011602482015270736c6963655f6f75744f66426f756e647360781b6044820152606490fd5b91610c88816106f981610b5c565b610c9783516107108385610b6a565b80610cb057505050604051600081526020810160405290565b60405192601f821692831560051b80858701019484860193010101905b808410610ce55750508252601f01601f191660405290565b9092602080918551815201930190610ccd565b908160209103126101c0575190565b60005460405163b3596f0760e01b81526001600160a01b039182166004820152929160209184916024918391165afa9182156104b157600092610d78575b508115610d67576106cc91610d5991610b8d565b670de0b6b3a7640000900490565b635a4d2e9d60e11b60005260046000fd5b610d9b91925060203d602011610da2575b610d938183610142565b810190610cf8565b9038610d45565b503d610d8956fef0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00a164736f6c634300081b000a";

type ETHGuardConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: ETHGuardConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class ETHGuard__factory extends ContractFactory {
  constructor(...args: ETHGuardConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override getDeployTransaction(
    overrides?: NonPayableOverrides & { from?: string }
  ): Promise<ContractDeployTransaction> {
    return super.getDeployTransaction(overrides || {});
  }
  override deploy(overrides?: NonPayableOverrides & { from?: string }) {
    return super.deploy(overrides || {}) as Promise<
      ETHGuard & {
        deploymentTransaction(): ContractTransactionResponse;
      }
    >;
  }
  override connect(runner: ContractRunner | null): ETHGuard__factory {
    return super.connect(runner) as ETHGuard__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ETHGuardInterface {
    return new Interface(_abi) as ETHGuardInterface;
  }
  static connect(address: string, runner?: ContractRunner | null): ETHGuard {
    return new Contract(address, _abi, runner) as unknown as ETHGuard;
  }
}

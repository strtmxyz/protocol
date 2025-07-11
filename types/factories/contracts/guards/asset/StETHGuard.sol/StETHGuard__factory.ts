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
import type { NonPayableOverrides } from "../../../../../common";
import type {
  StETHGuard,
  StETHGuardInterface,
} from "../../../../../contracts/guards/asset/StETHGuard.sol/StETHGuard";

const _abi = [
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
    name: "NotInitializing",
    type: "error",
  },
  {
    inputs: [],
    name: "PayableAmountMustBeZero",
    type: "error",
  },
  {
    inputs: [],
    name: "ReadingBytesOutOfBounds",
    type: "error",
  },
  {
    inputs: [],
    name: "UnsupportedAsset",
    type: "error",
  },
  {
    inputs: [],
    name: "UnsupportedSpenderApproval",
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
    name: "ETH_ADDRESS",
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
    name: "STETH_ADDRESS",
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
        name: "_WETH",
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
        name: "_vault",
        type: "address",
      },
      {
        internalType: "address",
        name: "_to",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "_data",
        type: "bytes",
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
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_vault",
        type: "address",
      },
      {
        internalType: "address",
        name: "_to",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "_data",
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
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608080604052346015576117bd908161001b8239f35b600080fdfe6080604052600436101561001257600080fd5b60003560e01c8062451d8b1461014657806309ff5c7d146101415780631053f9521461013c5780631d81e80f146101375780631eba307714610132578063293d80631461012d57806341dc16c3146101285780636179309d14610123578063689015131461011e57806382f86acc14610119578063998546e314610114578063a734f06e1461010f578063ad5c46481461010a578063bd125da414610105578063c3c6279f14610100578063c4d66de8146100fb578063cf54aaa0146100f6578063d4fac45d146100f15763db896b57146100ec57600080fd5b610c4e565b610c1a565b610b87565b610a1e565b6109f8565b6107d7565b6107ae565b610792565b610761565b61072f565b610716565b610689565b610598565b610526565b6104ff565b61045e565b61036c565b610282565b61015e565b6001600160a01b03909116815260200190565b3461018d57600036600319011261018d57602060405173ae7ab96520de3a18e5e111b5eaab095312d7fe848152f35b600080fd5b634e487b7160e01b600052604160045260246000fd5b601f909101601f19168101906001600160401b038211908210176101cb57604052565b610192565b6001600160401b0381116101cb57601f01601f191660200190565b9291926101f7826101d0565b9161020560405193846101a8565b82948184528183011161018d578281602093846000960137010152565b9080601f8301121561018d5781602061023d933591016101eb565b90565b60ff81160361018d57565b604060031982011261018d57600435906001600160401b03821161018d5761027591600401610222565b9060243561023d81610240565b3461018d576102a36102af60ff6102a861029b3661024b565b949094610ce4565b610cf9565b168261139b565b906004820191828111610307576102c6838361139b565b801561030c578060051b90810460200361030757600491010180921161030757610303916102f39161139b565b6040519081529081906020820190565b0390f35b610cce565b631754cda560e31b60005260046000fd5b60005b8381106103305750506000910152565b8181015183820152602001610320565b60409160208252610360815180928160208601526020868601910161031d565b601f01601f1916010190565b3461018d57606036600319011261018d576004356001600160401b03811161018d5761039c903690600401610222565b602435906103a982610240565b60443591601483101561043d578260051b9280840460201490151715610307576103d76102a360ff92610ce4565b16828101809111610307576103ec908261139b565b60048101918282116103075761042b6104268561042161041b6104156103039961043199610d35565b8661139b565b95610d0b565b610d35565b610d19565b90611434565b60405191829182610340565b62ed0ab960e11b60005260046000fd5b6001600160a01b0381160361018d57565b3461018d57606036600319011261018d5760043561047b8161044d565b60046024359161048a8361044d565b60405163c45a015560e01b81529160443591602091849182906001600160a01b03165afa9283156104fa57610303936102f3936000916104cb575b506114d2565b6104ed915060203d6020116104f3575b6104e581836101a8565b810190610d6b565b386104c5565b503d6104db565b610d80565b3461018d57602036600319011261018d576040516004356001600160a01b03168152602090f35b3461018d57604036600319011261018d576004356001600160401b03811161018d57610556903690600401610222565b6024359080516004830190818411610307571061058757016020908101516040516001600160e01b03199091168152f35b631853ab7360e21b60005260046000fd5b3461018d57606036600319011261018d576004356001600160401b03811161018d576105c8903690600401610222565b6024356105d481610240565b6105f860ff6105f16102a3604435946105ec86610240565b610ce4565b168361139b565b90600482018092116103075761060e828461139b565b90811561030c5760ff168091111561064b576001019182600111610307576106456102f39261063f61030395610d42565b90610d35565b9061139b565b633135ee2560e21b60005260046000fd5b9181601f8401121561018d578235916001600160401b03831161018d576020838186019501011161018d57565b3461018d57606036600319011261018d576004356106a68161044d565b6024356106b28161044d565b604435906001600160401b03821161018d576020926106d86106e093369060040161065c565b929091610e54565b61ffff60405191168152f35b602060031982011261018d57600435906001600160401b03821161018d5761023d91600401610222565b3461018d5761030361043161072a366106ec565b611201565b3461018d5760206107596102a360ff61075261074a3661024b565b909390610ce4565b169061139b565b604051908152f35b3461018d576102a361077a60ff6102a861029b3661024b565b9060048201809211610307576020916107599161139b565b3461018d57600036600319011261018d57602060405160008152f35b3461018d57600036600319011261018d576000546040516001600160a01b039091168152602090f35b3461018d57608036600319011261018d576004356107f48161044d565b6024356108008161044d565b6044356001600160401b03811161018d5761081f90369060040161065c565b6064359291630d0e30db60e41b6001600160e01b03196108486108433686866101eb565b610d8c565b1614806109ca575b806109c1575b15610996575050604051634df48c7360e11b81526001600160a01b0384169160209082908190610889906004830161014b565b0381855afa9081156104fa57600091610977575b501561093757604051634df48c7360e11b81526000600482015290602090829060249082905afa9081156104fa57600091610948575b5015610937576000547f886680222fab5497ac86bd83975ffc3d4312e8e6837dcf7e40a054f1973585db9290610919906001600160a01b03169260405193849384610dc3565b0390a161030360095b60405161ffff90911681529081906020820190565b630928045160e21b60005260046000fd5b61096a915060203d602011610970575b61096281836101a8565b810190610d9c565b386108d3565b503d610958565b610990915060203d6020116109705761096281836101a8565b3861089d565b909193926109b057610303936109ab93610e54565b610922565b630b09355d60e01b60005260046000fd5b50831515610856565b506000546109e8906001600160a01b03165b6001600160a01b031690565b6001600160a01b03841614610850565b3461018d576020610a0b610843366106ec565b6040516001600160e01b03199091168152f35b3461018d57602036600319011261018d57600435610a3b8161044d565b600080516020611791833981519152549060ff604083901c1615916001600160401b031680159081610b7f575b6001149081610b75575b159081610b6c575b50610b5b5760008051602061179183398151915280546001600160401b0319166001179055610aca9082610b1957600080546001600160a01b0319166001600160a01b0392909216919091179055565b610ad057005b600080516020611791833981519152805460ff60401b19169055604051600181527fc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d290602090a1005b600080516020611791833981519152805460ff60401b1916600160401b179055600080546001600160a01b0319166001600160a01b0392909216919091179055565b63f92ee8a960e01b60005260046000fd5b90501538610a7a565b303b159150610a72565b839150610a68565b3461018d57602036600319011261018d57600460208135610ba78161044d565b60405163313ce56760e01b815292839182906001600160a01b03165afa80156104fa5761030391600091610beb575b5060405160ff90911681529081906020820190565b610c0d915060203d602011610c13575b610c0581836101a8565b8101906112c1565b38610bd6565b503d610bfb565b3461018d57604036600319011261018d576020610759600435610c3c8161044d565b60243590610c498261044d565b6112d6565b3461018d57606036600319011261018d576004356001600160401b03811161018d57610c7e903690600401610222565b602435906044359060008151838501908186116103075710610cbf5750602092839101015190820380610cb5575b50604051908152f35b60031b1c38610cac565b631853ab7360e21b8152600490fd5b634e487b7160e01b600052601160045260246000fd5b60051b90611fe060e083169216820361030757565b60ff60049116019060ff821161030757565b906004820180921161030757565b906020820180921161030757565b90601f820180921161030757565b9190820180921161030757565b908160051b918083046020149015171561030757565b8181029291811591840414171561030757565b9081602091031261018d575161023d8161044d565b6040513d6000823e3d90fd5b6004815110610587576020015190565b9081602091031261018d5751801515810361018d5790565b9081602091031261018d575190565b6001600160a01b03918216815291166020820152604081019190915260600190565b919060408382031261018d578251610dfc8161044d565b602084015190936001600160401b03821161018d570181601f8201121561018d578051610e28816101d0565b92610e3660405194856101a8565b8184526020828401011161018d5761023d916020808501910161031d565b600093926001600160e01b0319610e6f6108433687856101eb565b1663095ea7b360e01b81036110a25750610eae9192939450610ea990610ea16109dc610e9c3689856101eb565b6112a1565b9536916101eb565b6112b1565b60405163c45a015560e01b81529093906001600160a01b038316602082600481845afa9182156104fa57600092611081575b5060206040518092634df48c7360e11b82528180610f018a6004830161014b565b03915afa60009181611060575b5061105b575060405163cc435bf360e01b815260208180610f32886004830161014b565b03816001600160a01b0386165afa9081156104fa5760009161103c575b505b156109375760006040518092631c09fa9b60e21b82528180610f76876004830161014b565b03916001600160a01b03165afa9081156104fa57600091611018575b506001600160a01b0316801590811561100e575b50610ffd57604080516001600160a01b039384168152938316602085015291169082015260608101919091527f64d4ed24bb3d6bfdd667acaeaad20f8795915514e1c67fb333b1ee94fe970d1590608090a1600190565b633790c8eb60e21b60005260046000fd5b9050301438610fa6565b61103591503d806000833e61102d81836101a8565b810190610de5565b5038610f92565b611055915060203d6020116109705761096281836101a8565b38610f4f565b610f51565b61107a91925060203d6020116109705761096281836101a8565b9038610f0e565b61109b91925060203d6020116104f3576104e581836101a8565b9038610ee0565b6000546110b7906001600160a01b03166109dc565b6001600160a01b038516146110cf575b505050505090565b632e1a7d4d60e01b146110e3575b806110c7565b604051634df48c7360e11b815293945091929091906001600160a01b0383169060208180611114886004830161014b565b0381855afa9081156104fa576000916111e2575b501561093757604051634df48c7360e11b81526000600482015290602090829060249082905afa9081156104fa576000916111c3575b5015610937576111a961119a61072a6111b5937f11b8c8bf8a65d98dc04255ca61faa6cf1b149350336c90d12227ca1463b5970d9736916101eb565b60208082518301019101610db4565b60405193849384610dc3565b0390a1600a388080806110dd565b6111dc915060203d6020116109705761096281836101a8565b3861115e565b6111fb915060203d6020116109705761096281836101a8565b38611128565b80516003198101818111610307576112238161121c81610d27565b10156113b7565b61123a8351611233836004610d35565b11156113f4565b8061125357505050604051600081526020810160405290565b604051926004601f8316801560051b908181880101956003199087010193010101905b80841061128e5750508252601f01601f191660405290565b9092602080918551815201930190611276565b61023d9060ff6107526000610cf9565b61023d9060ff6107526020610cf9565b9081602091031261018d575161023d81610240565b6001600160a01b039091169060209073ae7ab96520de3a18e5e111b5eaab095312d7fe848314611362576040516370a0823160e01b81526001600160a01b03909116600482015291829060249082905afa9081156104fa57600091611339575090565b61023d915060203d60201161135b575b61135381836101a8565b810190610db4565b503d611349565b6040516370a0823160e01b81526001600160a01b03909116600482015291829060249082905afa9081156104fa57600091611339575090565b9081516020820190818311610307571061058757016020015190565b156113be57565b60405162461bcd60e51b815260206004820152600e60248201526d736c6963655f6f766572666c6f7760901b6044820152606490fd5b156113fb57565b60405162461bcd60e51b8152602060048201526011602482015270736c6963655f6f75744f66426f756e647360781b6044820152606490fd5b916114428161121c81610d27565b61145183516112338385610d35565b8061146a57505050604051600081526020810160405290565b60405192601f821692831560051b80858701019484860193010101905b80841061149f5750508252601f01601f191660405290565b9092602080918551815201930190611487565b81156114bc570490565b634e487b7160e01b600052601260045260246000fd5b919073ae7ab96520de3a18e5e111b5eaab095312d7fe83196001600160a01b03821601611579575061150390611645565b60405163b3596f0760e01b8152600060048201529091602090829060249082906001600160a01b03165afa80156104fa5761023d9261154a92600092611558575b50610d58565b670de0b6b3a7640000900490565b61157291925060203d60201161135b5761135381836101a8565b9038611544565b90916020604051809263b3596f0760e01b8252818061159b876004830161014b565b03916001600160a01b03165afa9081156104fa576004936020926115c6926000916116285750610d58565b60405163313ce56760e01b815293909284919082906001600160a01b03165afa9182156104fa5761023d9261160391600091611609575b5061177f565b906114b2565b611622915060203d602011610c1357610c0581836101a8565b386115fd565b61163f9150843d861161135b5761135381836101a8565b38611544565b604051630f451f7160e31b81526004810182905260208160248173ae7ab96520de3a18e5e111b5eaab095312d7fe845afa6000918161175e575b506117595750604051636a80179760e11b815260208160048173ae7ab96520de3a18e5e111b5eaab095312d7fe845afa60009181611738575b506116c1575090565b604051631be7ed6560e11b815260208160048173ae7ab96520de3a18e5e111b5eaab095312d7fe845afa60009181611717575b506116ff575b505090565b81156116fa576117129061023d93610d58565b6114b2565b61173191925060203d60201161135b5761135381836101a8565b90386116f4565b61175291925060203d60201161135b5761135381836101a8565b90386116b8565b905090565b61177891925060203d60201161135b5761135381836101a8565b903861167f565b60ff16604d811161030757600a0a9056fef0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00a164736f6c634300081b000a";

type StETHGuardConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: StETHGuardConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class StETHGuard__factory extends ContractFactory {
  constructor(...args: StETHGuardConstructorParams) {
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
      StETHGuard & {
        deploymentTransaction(): ContractTransactionResponse;
      }
    >;
  }
  override connect(runner: ContractRunner | null): StETHGuard__factory {
    return super.connect(runner) as StETHGuard__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): StETHGuardInterface {
    return new Interface(_abi) as StETHGuardInterface;
  }
  static connect(address: string, runner?: ContractRunner | null): StETHGuard {
    return new Contract(address, _abi, runner) as unknown as StETHGuard;
  }
}

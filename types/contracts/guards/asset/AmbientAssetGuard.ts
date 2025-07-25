/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumberish,
  BytesLike,
  FunctionFragment,
  Result,
  Interface,
  EventFragment,
  AddressLike,
  ContractRunner,
  ContractMethod,
  Listener,
} from "ethers";
import type {
  TypedContractEvent,
  TypedDeferredTopicFilter,
  TypedEventLog,
  TypedLogDescription,
  TypedListener,
  TypedContractMethod,
} from "../../../common";

export interface AmbientAssetGuardInterface extends Interface {
  getFunction(
    nameOrSignature:
      | "calcValue"
      | "convert32toAddress"
      | "crocQueryEndpoint"
      | "getArrayIndex"
      | "getArrayLast"
      | "getArrayLength"
      | "getBalance"
      | "getBytes"
      | "getDecimals"
      | "getInput"
      | "getMethod"
      | "getParams"
      | "getRangeTokens"
      | "initialize"
      | "poolConfigs"
      | "read32"
      | "read4left"
      | "setPoolConfig"
      | "txGuard(address,address,bytes)"
      | "txGuard(address,address,bytes,uint256)"
  ): FunctionFragment;

  getEvent(
    nameOrSignatureOrTopic:
      | "ERC20Approval"
      | "ERC721Approval"
      | "Initialized"
      | "UnwrapNativeToken"
      | "WrapNativeToken"
  ): EventFragment;

  encodeFunctionData(
    functionFragment: "calcValue",
    values: [AddressLike, AddressLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "convert32toAddress",
    values: [BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "crocQueryEndpoint",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getArrayIndex",
    values: [BytesLike, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "getArrayLast",
    values: [BytesLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "getArrayLength",
    values: [BytesLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "getBalance",
    values: [AddressLike, AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "getBytes",
    values: [BytesLike, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "getDecimals",
    values: [AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "getInput",
    values: [BytesLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "getMethod",
    values: [BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "getParams",
    values: [BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "getRangeTokens",
    values: [AddressLike, AddressLike, AddressLike, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "initialize",
    values: [AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "poolConfigs",
    values: [AddressLike, AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "read32",
    values: [BytesLike, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "read4left",
    values: [BytesLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "setPoolConfig",
    values: [AddressLike, AddressLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "txGuard(address,address,bytes)",
    values: [AddressLike, AddressLike, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "txGuard(address,address,bytes,uint256)",
    values: [AddressLike, AddressLike, BytesLike, BigNumberish]
  ): string;

  decodeFunctionResult(functionFragment: "calcValue", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "convert32toAddress",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "crocQueryEndpoint",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getArrayIndex",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getArrayLast",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getArrayLength",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "getBalance", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "getBytes", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getDecimals",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "getInput", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "getMethod", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "getParams", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getRangeTokens",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "initialize", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "poolConfigs",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "read32", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "read4left", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "setPoolConfig",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "txGuard(address,address,bytes)",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "txGuard(address,address,bytes,uint256)",
    data: BytesLike
  ): Result;
}

export namespace ERC20ApprovalEvent {
  export type InputTuple = [
    vault: AddressLike,
    token: AddressLike,
    spender: AddressLike,
    amount: BigNumberish
  ];
  export type OutputTuple = [
    vault: string,
    token: string,
    spender: string,
    amount: bigint
  ];
  export interface OutputObject {
    vault: string;
    token: string;
    spender: string;
    amount: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace ERC721ApprovalEvent {
  export type InputTuple = [
    vault: AddressLike,
    token: AddressLike,
    spender: AddressLike,
    tokenId: BigNumberish
  ];
  export type OutputTuple = [
    vault: string,
    token: string,
    spender: string,
    tokenId: bigint
  ];
  export interface OutputObject {
    vault: string;
    token: string;
    spender: string;
    tokenId: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace InitializedEvent {
  export type InputTuple = [version: BigNumberish];
  export type OutputTuple = [version: bigint];
  export interface OutputObject {
    version: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace UnwrapNativeTokenEvent {
  export type InputTuple = [
    vault: AddressLike,
    token: AddressLike,
    amount: BigNumberish
  ];
  export type OutputTuple = [vault: string, token: string, amount: bigint];
  export interface OutputObject {
    vault: string;
    token: string;
    amount: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace WrapNativeTokenEvent {
  export type InputTuple = [
    vault: AddressLike,
    token: AddressLike,
    amount: BigNumberish
  ];
  export type OutputTuple = [vault: string, token: string, amount: bigint];
  export interface OutputObject {
    vault: string;
    token: string;
    amount: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export interface AmbientAssetGuard extends BaseContract {
  connect(runner?: ContractRunner | null): AmbientAssetGuard;
  waitForDeployment(): Promise<this>;

  interface: AmbientAssetGuardInterface;

  queryFilter<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEventLog<TCEvent>>>;
  queryFilter<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEventLog<TCEvent>>>;

  on<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    listener: TypedListener<TCEvent>
  ): Promise<this>;
  on<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    listener: TypedListener<TCEvent>
  ): Promise<this>;

  once<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    listener: TypedListener<TCEvent>
  ): Promise<this>;
  once<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    listener: TypedListener<TCEvent>
  ): Promise<this>;

  listeners<TCEvent extends TypedContractEvent>(
    event: TCEvent
  ): Promise<Array<TypedListener<TCEvent>>>;
  listeners(eventName?: string): Promise<Array<Listener>>;
  removeAllListeners<TCEvent extends TypedContractEvent>(
    event?: TCEvent
  ): Promise<this>;

  calcValue: TypedContractMethod<
    [vault: AddressLike, asset: AddressLike, balance: BigNumberish],
    [bigint],
    "view"
  >;

  convert32toAddress: TypedContractMethod<[data: BytesLike], [string], "view">;

  crocQueryEndpoint: TypedContractMethod<[], [string], "view">;

  getArrayIndex: TypedContractMethod<
    [data: BytesLike, inputNum: BigNumberish, arrayIndex: BigNumberish],
    [string],
    "view"
  >;

  getArrayLast: TypedContractMethod<
    [data: BytesLike, inputNum: BigNumberish],
    [string],
    "view"
  >;

  getArrayLength: TypedContractMethod<
    [data: BytesLike, inputNum: BigNumberish],
    [bigint],
    "view"
  >;

  getBalance: TypedContractMethod<
    [vault: AddressLike, asset: AddressLike],
    [bigint],
    "view"
  >;

  getBytes: TypedContractMethod<
    [data: BytesLike, inputNum: BigNumberish, offset: BigNumberish],
    [string],
    "view"
  >;

  getDecimals: TypedContractMethod<[arg0: AddressLike], [bigint], "view">;

  getInput: TypedContractMethod<
    [data: BytesLike, inputNum: BigNumberish],
    [string],
    "view"
  >;

  getMethod: TypedContractMethod<[data: BytesLike], [string], "view">;

  getParams: TypedContractMethod<[data: BytesLike], [string], "view">;

  getRangeTokens: TypedContractMethod<
    [
      vault: AddressLike,
      baseAsset: AddressLike,
      quoteAsset: AddressLike,
      bidTick: BigNumberish,
      askTick: BigNumberish
    ],
    [
      [bigint, bigint, bigint] & {
        liq: bigint;
        baseQty: bigint;
        quoteQty: bigint;
      }
    ],
    "view"
  >;

  initialize: TypedContractMethod<
    [_crocQueryEndpoint: AddressLike],
    [void],
    "nonpayable"
  >;

  poolConfigs: TypedContractMethod<
    [arg0: AddressLike, arg1: AddressLike],
    [bigint],
    "view"
  >;

  read32: TypedContractMethod<
    [data: BytesLike, offset: BigNumberish, length: BigNumberish],
    [string],
    "view"
  >;

  read4left: TypedContractMethod<
    [data: BytesLike, offset: BigNumberish],
    [string],
    "view"
  >;

  setPoolConfig: TypedContractMethod<
    [baseAsset: AddressLike, quoteAsset: AddressLike, poolIdx: BigNumberish],
    [void],
    "nonpayable"
  >;

  "txGuard(address,address,bytes)": TypedContractMethod<
    [arg0: AddressLike, arg1: AddressLike, arg2: BytesLike],
    [bigint],
    "view"
  >;

  "txGuard(address,address,bytes,uint256)": TypedContractMethod<
    [arg0: AddressLike, arg1: AddressLike, arg2: BytesLike, arg3: BigNumberish],
    [bigint],
    "view"
  >;

  getFunction<T extends ContractMethod = ContractMethod>(
    key: string | FunctionFragment
  ): T;

  getFunction(
    nameOrSignature: "calcValue"
  ): TypedContractMethod<
    [vault: AddressLike, asset: AddressLike, balance: BigNumberish],
    [bigint],
    "view"
  >;
  getFunction(
    nameOrSignature: "convert32toAddress"
  ): TypedContractMethod<[data: BytesLike], [string], "view">;
  getFunction(
    nameOrSignature: "crocQueryEndpoint"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "getArrayIndex"
  ): TypedContractMethod<
    [data: BytesLike, inputNum: BigNumberish, arrayIndex: BigNumberish],
    [string],
    "view"
  >;
  getFunction(
    nameOrSignature: "getArrayLast"
  ): TypedContractMethod<
    [data: BytesLike, inputNum: BigNumberish],
    [string],
    "view"
  >;
  getFunction(
    nameOrSignature: "getArrayLength"
  ): TypedContractMethod<
    [data: BytesLike, inputNum: BigNumberish],
    [bigint],
    "view"
  >;
  getFunction(
    nameOrSignature: "getBalance"
  ): TypedContractMethod<
    [vault: AddressLike, asset: AddressLike],
    [bigint],
    "view"
  >;
  getFunction(
    nameOrSignature: "getBytes"
  ): TypedContractMethod<
    [data: BytesLike, inputNum: BigNumberish, offset: BigNumberish],
    [string],
    "view"
  >;
  getFunction(
    nameOrSignature: "getDecimals"
  ): TypedContractMethod<[arg0: AddressLike], [bigint], "view">;
  getFunction(
    nameOrSignature: "getInput"
  ): TypedContractMethod<
    [data: BytesLike, inputNum: BigNumberish],
    [string],
    "view"
  >;
  getFunction(
    nameOrSignature: "getMethod"
  ): TypedContractMethod<[data: BytesLike], [string], "view">;
  getFunction(
    nameOrSignature: "getParams"
  ): TypedContractMethod<[data: BytesLike], [string], "view">;
  getFunction(
    nameOrSignature: "getRangeTokens"
  ): TypedContractMethod<
    [
      vault: AddressLike,
      baseAsset: AddressLike,
      quoteAsset: AddressLike,
      bidTick: BigNumberish,
      askTick: BigNumberish
    ],
    [
      [bigint, bigint, bigint] & {
        liq: bigint;
        baseQty: bigint;
        quoteQty: bigint;
      }
    ],
    "view"
  >;
  getFunction(
    nameOrSignature: "initialize"
  ): TypedContractMethod<
    [_crocQueryEndpoint: AddressLike],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "poolConfigs"
  ): TypedContractMethod<
    [arg0: AddressLike, arg1: AddressLike],
    [bigint],
    "view"
  >;
  getFunction(
    nameOrSignature: "read32"
  ): TypedContractMethod<
    [data: BytesLike, offset: BigNumberish, length: BigNumberish],
    [string],
    "view"
  >;
  getFunction(
    nameOrSignature: "read4left"
  ): TypedContractMethod<
    [data: BytesLike, offset: BigNumberish],
    [string],
    "view"
  >;
  getFunction(
    nameOrSignature: "setPoolConfig"
  ): TypedContractMethod<
    [baseAsset: AddressLike, quoteAsset: AddressLike, poolIdx: BigNumberish],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "txGuard(address,address,bytes)"
  ): TypedContractMethod<
    [arg0: AddressLike, arg1: AddressLike, arg2: BytesLike],
    [bigint],
    "view"
  >;
  getFunction(
    nameOrSignature: "txGuard(address,address,bytes,uint256)"
  ): TypedContractMethod<
    [arg0: AddressLike, arg1: AddressLike, arg2: BytesLike, arg3: BigNumberish],
    [bigint],
    "view"
  >;

  getEvent(
    key: "ERC20Approval"
  ): TypedContractEvent<
    ERC20ApprovalEvent.InputTuple,
    ERC20ApprovalEvent.OutputTuple,
    ERC20ApprovalEvent.OutputObject
  >;
  getEvent(
    key: "ERC721Approval"
  ): TypedContractEvent<
    ERC721ApprovalEvent.InputTuple,
    ERC721ApprovalEvent.OutputTuple,
    ERC721ApprovalEvent.OutputObject
  >;
  getEvent(
    key: "Initialized"
  ): TypedContractEvent<
    InitializedEvent.InputTuple,
    InitializedEvent.OutputTuple,
    InitializedEvent.OutputObject
  >;
  getEvent(
    key: "UnwrapNativeToken"
  ): TypedContractEvent<
    UnwrapNativeTokenEvent.InputTuple,
    UnwrapNativeTokenEvent.OutputTuple,
    UnwrapNativeTokenEvent.OutputObject
  >;
  getEvent(
    key: "WrapNativeToken"
  ): TypedContractEvent<
    WrapNativeTokenEvent.InputTuple,
    WrapNativeTokenEvent.OutputTuple,
    WrapNativeTokenEvent.OutputObject
  >;

  filters: {
    "ERC20Approval(address,address,address,uint256)": TypedContractEvent<
      ERC20ApprovalEvent.InputTuple,
      ERC20ApprovalEvent.OutputTuple,
      ERC20ApprovalEvent.OutputObject
    >;
    ERC20Approval: TypedContractEvent<
      ERC20ApprovalEvent.InputTuple,
      ERC20ApprovalEvent.OutputTuple,
      ERC20ApprovalEvent.OutputObject
    >;

    "ERC721Approval(address,address,address,uint256)": TypedContractEvent<
      ERC721ApprovalEvent.InputTuple,
      ERC721ApprovalEvent.OutputTuple,
      ERC721ApprovalEvent.OutputObject
    >;
    ERC721Approval: TypedContractEvent<
      ERC721ApprovalEvent.InputTuple,
      ERC721ApprovalEvent.OutputTuple,
      ERC721ApprovalEvent.OutputObject
    >;

    "Initialized(uint64)": TypedContractEvent<
      InitializedEvent.InputTuple,
      InitializedEvent.OutputTuple,
      InitializedEvent.OutputObject
    >;
    Initialized: TypedContractEvent<
      InitializedEvent.InputTuple,
      InitializedEvent.OutputTuple,
      InitializedEvent.OutputObject
    >;

    "UnwrapNativeToken(address,address,uint256)": TypedContractEvent<
      UnwrapNativeTokenEvent.InputTuple,
      UnwrapNativeTokenEvent.OutputTuple,
      UnwrapNativeTokenEvent.OutputObject
    >;
    UnwrapNativeToken: TypedContractEvent<
      UnwrapNativeTokenEvent.InputTuple,
      UnwrapNativeTokenEvent.OutputTuple,
      UnwrapNativeTokenEvent.OutputObject
    >;

    "WrapNativeToken(address,address,uint256)": TypedContractEvent<
      WrapNativeTokenEvent.InputTuple,
      WrapNativeTokenEvent.OutputTuple,
      WrapNativeTokenEvent.OutputObject
    >;
    WrapNativeToken: TypedContractEvent<
      WrapNativeTokenEvent.InputTuple,
      WrapNativeTokenEvent.OutputTuple,
      WrapNativeTokenEvent.OutputObject
    >;
  };
}

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

export interface IPlatformGuardInterface extends Interface {
  getFunction(
    nameOrSignature:
      | "platformName"
      | "txGuard(address,address,bytes)"
      | "txGuard(address,address,bytes,uint256)"
  ): FunctionFragment;

  getEvent(
    nameOrSignatureOrTopic:
      | "AddLiquidity"
      | "ExchangeFrom"
      | "ExchangeTo"
      | "RemoveLiquidity"
      | "UnwrapNativeToken"
      | "VertexDeposit"
      | "VertexSlowMode"
  ): EventFragment;

  encodeFunctionData(
    functionFragment: "platformName",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "txGuard(address,address,bytes)",
    values: [AddressLike, AddressLike, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "txGuard(address,address,bytes,uint256)",
    values: [AddressLike, AddressLike, BytesLike, BigNumberish]
  ): string;

  decodeFunctionResult(
    functionFragment: "platformName",
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

export namespace AddLiquidityEvent {
  export type InputTuple = [
    vault: AddressLike,
    dex: AddressLike,
    pair: AddressLike,
    params: BytesLike
  ];
  export type OutputTuple = [
    vault: string,
    dex: string,
    pair: string,
    params: string
  ];
  export interface OutputObject {
    vault: string;
    dex: string;
    pair: string;
    params: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace ExchangeFromEvent {
  export type InputTuple = [
    vault: AddressLike,
    dex: AddressLike,
    sourceAsset: AddressLike,
    sourceAmount: BigNumberish,
    dstAsset: AddressLike
  ];
  export type OutputTuple = [
    vault: string,
    dex: string,
    sourceAsset: string,
    sourceAmount: bigint,
    dstAsset: string
  ];
  export interface OutputObject {
    vault: string;
    dex: string;
    sourceAsset: string;
    sourceAmount: bigint;
    dstAsset: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace ExchangeToEvent {
  export type InputTuple = [
    vault: AddressLike,
    dex: AddressLike,
    sourceAsset: AddressLike,
    dstAsset: AddressLike,
    dstAmount: BigNumberish
  ];
  export type OutputTuple = [
    vault: string,
    dex: string,
    sourceAsset: string,
    dstAsset: string,
    dstAmount: bigint
  ];
  export interface OutputObject {
    vault: string;
    dex: string;
    sourceAsset: string;
    dstAsset: string;
    dstAmount: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace RemoveLiquidityEvent {
  export type InputTuple = [
    vault: AddressLike,
    dex: AddressLike,
    pair: AddressLike,
    params: BytesLike
  ];
  export type OutputTuple = [
    vault: string,
    dex: string,
    pair: string,
    params: string
  ];
  export interface OutputObject {
    vault: string;
    dex: string;
    pair: string;
    params: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace UnwrapNativeTokenEvent {
  export type InputTuple = [
    vault: AddressLike,
    dex: AddressLike,
    amountMinimum: BigNumberish
  ];
  export type OutputTuple = [vault: string, dex: string, amountMinimum: bigint];
  export interface OutputObject {
    vault: string;
    dex: string;
    amountMinimum: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace VertexDepositEvent {
  export type InputTuple = [
    vault: AddressLike,
    endpoint: AddressLike,
    amount: BigNumberish
  ];
  export type OutputTuple = [vault: string, endpoint: string, amount: bigint];
  export interface OutputObject {
    vault: string;
    endpoint: string;
    amount: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace VertexSlowModeEvent {
  export type InputTuple = [
    vault: AddressLike,
    endpoint: AddressLike,
    deadline: BigNumberish
  ];
  export type OutputTuple = [vault: string, endpoint: string, deadline: bigint];
  export interface OutputObject {
    vault: string;
    endpoint: string;
    deadline: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export interface IPlatformGuard extends BaseContract {
  connect(runner?: ContractRunner | null): IPlatformGuard;
  waitForDeployment(): Promise<this>;

  interface: IPlatformGuardInterface;

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

  platformName: TypedContractMethod<[], [string], "view">;

  "txGuard(address,address,bytes)": TypedContractMethod<
    [vault: AddressLike, to: AddressLike, data: BytesLike],
    [bigint],
    "nonpayable"
  >;

  "txGuard(address,address,bytes,uint256)": TypedContractMethod<
    [
      vault: AddressLike,
      to: AddressLike,
      data: BytesLike,
      nativeAmount: BigNumberish
    ],
    [bigint],
    "nonpayable"
  >;

  getFunction<T extends ContractMethod = ContractMethod>(
    key: string | FunctionFragment
  ): T;

  getFunction(
    nameOrSignature: "platformName"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "txGuard(address,address,bytes)"
  ): TypedContractMethod<
    [vault: AddressLike, to: AddressLike, data: BytesLike],
    [bigint],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "txGuard(address,address,bytes,uint256)"
  ): TypedContractMethod<
    [
      vault: AddressLike,
      to: AddressLike,
      data: BytesLike,
      nativeAmount: BigNumberish
    ],
    [bigint],
    "nonpayable"
  >;

  getEvent(
    key: "AddLiquidity"
  ): TypedContractEvent<
    AddLiquidityEvent.InputTuple,
    AddLiquidityEvent.OutputTuple,
    AddLiquidityEvent.OutputObject
  >;
  getEvent(
    key: "ExchangeFrom"
  ): TypedContractEvent<
    ExchangeFromEvent.InputTuple,
    ExchangeFromEvent.OutputTuple,
    ExchangeFromEvent.OutputObject
  >;
  getEvent(
    key: "ExchangeTo"
  ): TypedContractEvent<
    ExchangeToEvent.InputTuple,
    ExchangeToEvent.OutputTuple,
    ExchangeToEvent.OutputObject
  >;
  getEvent(
    key: "RemoveLiquidity"
  ): TypedContractEvent<
    RemoveLiquidityEvent.InputTuple,
    RemoveLiquidityEvent.OutputTuple,
    RemoveLiquidityEvent.OutputObject
  >;
  getEvent(
    key: "UnwrapNativeToken"
  ): TypedContractEvent<
    UnwrapNativeTokenEvent.InputTuple,
    UnwrapNativeTokenEvent.OutputTuple,
    UnwrapNativeTokenEvent.OutputObject
  >;
  getEvent(
    key: "VertexDeposit"
  ): TypedContractEvent<
    VertexDepositEvent.InputTuple,
    VertexDepositEvent.OutputTuple,
    VertexDepositEvent.OutputObject
  >;
  getEvent(
    key: "VertexSlowMode"
  ): TypedContractEvent<
    VertexSlowModeEvent.InputTuple,
    VertexSlowModeEvent.OutputTuple,
    VertexSlowModeEvent.OutputObject
  >;

  filters: {
    "AddLiquidity(address,address,address,bytes)": TypedContractEvent<
      AddLiquidityEvent.InputTuple,
      AddLiquidityEvent.OutputTuple,
      AddLiquidityEvent.OutputObject
    >;
    AddLiquidity: TypedContractEvent<
      AddLiquidityEvent.InputTuple,
      AddLiquidityEvent.OutputTuple,
      AddLiquidityEvent.OutputObject
    >;

    "ExchangeFrom(address,address,address,uint256,address)": TypedContractEvent<
      ExchangeFromEvent.InputTuple,
      ExchangeFromEvent.OutputTuple,
      ExchangeFromEvent.OutputObject
    >;
    ExchangeFrom: TypedContractEvent<
      ExchangeFromEvent.InputTuple,
      ExchangeFromEvent.OutputTuple,
      ExchangeFromEvent.OutputObject
    >;

    "ExchangeTo(address,address,address,address,uint256)": TypedContractEvent<
      ExchangeToEvent.InputTuple,
      ExchangeToEvent.OutputTuple,
      ExchangeToEvent.OutputObject
    >;
    ExchangeTo: TypedContractEvent<
      ExchangeToEvent.InputTuple,
      ExchangeToEvent.OutputTuple,
      ExchangeToEvent.OutputObject
    >;

    "RemoveLiquidity(address,address,address,bytes)": TypedContractEvent<
      RemoveLiquidityEvent.InputTuple,
      RemoveLiquidityEvent.OutputTuple,
      RemoveLiquidityEvent.OutputObject
    >;
    RemoveLiquidity: TypedContractEvent<
      RemoveLiquidityEvent.InputTuple,
      RemoveLiquidityEvent.OutputTuple,
      RemoveLiquidityEvent.OutputObject
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

    "VertexDeposit(address,address,uint256)": TypedContractEvent<
      VertexDepositEvent.InputTuple,
      VertexDepositEvent.OutputTuple,
      VertexDepositEvent.OutputObject
    >;
    VertexDeposit: TypedContractEvent<
      VertexDepositEvent.InputTuple,
      VertexDepositEvent.OutputTuple,
      VertexDepositEvent.OutputObject
    >;

    "VertexSlowMode(address,address,uint256)": TypedContractEvent<
      VertexSlowModeEvent.InputTuple,
      VertexSlowModeEvent.OutputTuple,
      VertexSlowModeEvent.OutputObject
    >;
    VertexSlowMode: TypedContractEvent<
      VertexSlowModeEvent.InputTuple,
      VertexSlowModeEvent.OutputTuple,
      VertexSlowModeEvent.OutputObject
    >;
  };
}

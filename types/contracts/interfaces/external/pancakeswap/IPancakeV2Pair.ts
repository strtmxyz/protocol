/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BytesLike,
  FunctionFragment,
  Result,
  Interface,
  AddressLike,
  ContractRunner,
  ContractMethod,
  Listener,
} from "ethers";
import type {
  TypedContractEvent,
  TypedDeferredTopicFilter,
  TypedEventLog,
  TypedListener,
  TypedContractMethod,
} from "../../../../common";

export interface IPancakeV2PairInterface extends Interface {
  getFunction(
    nameOrSignature:
      | "burn"
      | "getReserves"
      | "price0CumulativeLast"
      | "price1CumulativeLast"
      | "token0"
      | "token1"
      | "totalSupply"
  ): FunctionFragment;

  encodeFunctionData(functionFragment: "burn", values: [AddressLike]): string;
  encodeFunctionData(
    functionFragment: "getReserves",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "price0CumulativeLast",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "price1CumulativeLast",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "token0", values?: undefined): string;
  encodeFunctionData(functionFragment: "token1", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "totalSupply",
    values?: undefined
  ): string;

  decodeFunctionResult(functionFragment: "burn", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getReserves",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "price0CumulativeLast",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "price1CumulativeLast",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "token0", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "token1", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "totalSupply",
    data: BytesLike
  ): Result;
}

export interface IPancakeV2Pair extends BaseContract {
  connect(runner?: ContractRunner | null): IPancakeV2Pair;
  waitForDeployment(): Promise<this>;

  interface: IPancakeV2PairInterface;

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

  burn: TypedContractMethod<
    [to: AddressLike],
    [[bigint, bigint] & { amount0: bigint; amount1: bigint }],
    "nonpayable"
  >;

  getReserves: TypedContractMethod<
    [],
    [
      [bigint, bigint, bigint] & {
        reserve0: bigint;
        reserve1: bigint;
        blockTimestampLast: bigint;
      }
    ],
    "view"
  >;

  price0CumulativeLast: TypedContractMethod<[], [bigint], "view">;

  price1CumulativeLast: TypedContractMethod<[], [bigint], "view">;

  token0: TypedContractMethod<[], [string], "view">;

  token1: TypedContractMethod<[], [string], "view">;

  totalSupply: TypedContractMethod<[], [bigint], "view">;

  getFunction<T extends ContractMethod = ContractMethod>(
    key: string | FunctionFragment
  ): T;

  getFunction(
    nameOrSignature: "burn"
  ): TypedContractMethod<
    [to: AddressLike],
    [[bigint, bigint] & { amount0: bigint; amount1: bigint }],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "getReserves"
  ): TypedContractMethod<
    [],
    [
      [bigint, bigint, bigint] & {
        reserve0: bigint;
        reserve1: bigint;
        blockTimestampLast: bigint;
      }
    ],
    "view"
  >;
  getFunction(
    nameOrSignature: "price0CumulativeLast"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "price1CumulativeLast"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "token0"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "token1"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "totalSupply"
  ): TypedContractMethod<[], [bigint], "view">;

  filters: {};
}

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

export interface IPancakeV2RouterInterface extends Interface {
  getFunction(
    nameOrSignature:
      | "WETH"
      | "addLiquidity"
      | "factory"
      | "getAmountsIn"
      | "getAmountsOut"
      | "removeLiquidity"
      | "swapExactTokensForTokens"
      | "swapTokensForExactTokens"
  ): FunctionFragment;

  encodeFunctionData(functionFragment: "WETH", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "addLiquidity",
    values: [
      AddressLike,
      AddressLike,
      BigNumberish,
      BigNumberish,
      BigNumberish,
      BigNumberish,
      AddressLike,
      BigNumberish
    ]
  ): string;
  encodeFunctionData(functionFragment: "factory", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "getAmountsIn",
    values: [BigNumberish, AddressLike[]]
  ): string;
  encodeFunctionData(
    functionFragment: "getAmountsOut",
    values: [BigNumberish, AddressLike[]]
  ): string;
  encodeFunctionData(
    functionFragment: "removeLiquidity",
    values: [
      AddressLike,
      AddressLike,
      BigNumberish,
      BigNumberish,
      BigNumberish,
      AddressLike,
      BigNumberish
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "swapExactTokensForTokens",
    values: [
      BigNumberish,
      BigNumberish,
      AddressLike[],
      AddressLike,
      BigNumberish
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "swapTokensForExactTokens",
    values: [
      BigNumberish,
      BigNumberish,
      AddressLike[],
      AddressLike,
      BigNumberish
    ]
  ): string;

  decodeFunctionResult(functionFragment: "WETH", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "addLiquidity",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "factory", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getAmountsIn",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getAmountsOut",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "removeLiquidity",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "swapExactTokensForTokens",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "swapTokensForExactTokens",
    data: BytesLike
  ): Result;
}

export interface IPancakeV2Router extends BaseContract {
  connect(runner?: ContractRunner | null): IPancakeV2Router;
  waitForDeployment(): Promise<this>;

  interface: IPancakeV2RouterInterface;

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

  WETH: TypedContractMethod<[], [string], "view">;

  addLiquidity: TypedContractMethod<
    [
      tokenA: AddressLike,
      tokenB: AddressLike,
      amountADesired: BigNumberish,
      amountBDesired: BigNumberish,
      amountAMin: BigNumberish,
      amountBMin: BigNumberish,
      to: AddressLike,
      deadline: BigNumberish
    ],
    [
      [bigint, bigint, bigint] & {
        amountA: bigint;
        amountB: bigint;
        liquidity: bigint;
      }
    ],
    "nonpayable"
  >;

  factory: TypedContractMethod<[], [string], "view">;

  getAmountsIn: TypedContractMethod<
    [amountOut: BigNumberish, path: AddressLike[]],
    [bigint[]],
    "view"
  >;

  getAmountsOut: TypedContractMethod<
    [amountIn: BigNumberish, path: AddressLike[]],
    [bigint[]],
    "view"
  >;

  removeLiquidity: TypedContractMethod<
    [
      tokenA: AddressLike,
      tokenB: AddressLike,
      liquidity: BigNumberish,
      amountAMin: BigNumberish,
      amountBMin: BigNumberish,
      to: AddressLike,
      deadline: BigNumberish
    ],
    [[bigint, bigint] & { amountA: bigint; amountB: bigint }],
    "nonpayable"
  >;

  swapExactTokensForTokens: TypedContractMethod<
    [
      amountIn: BigNumberish,
      amountOutMin: BigNumberish,
      path: AddressLike[],
      to: AddressLike,
      deadline: BigNumberish
    ],
    [bigint[]],
    "nonpayable"
  >;

  swapTokensForExactTokens: TypedContractMethod<
    [
      amountOut: BigNumberish,
      amountInMax: BigNumberish,
      path: AddressLike[],
      to: AddressLike,
      deadline: BigNumberish
    ],
    [bigint[]],
    "nonpayable"
  >;

  getFunction<T extends ContractMethod = ContractMethod>(
    key: string | FunctionFragment
  ): T;

  getFunction(
    nameOrSignature: "WETH"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "addLiquidity"
  ): TypedContractMethod<
    [
      tokenA: AddressLike,
      tokenB: AddressLike,
      amountADesired: BigNumberish,
      amountBDesired: BigNumberish,
      amountAMin: BigNumberish,
      amountBMin: BigNumberish,
      to: AddressLike,
      deadline: BigNumberish
    ],
    [
      [bigint, bigint, bigint] & {
        amountA: bigint;
        amountB: bigint;
        liquidity: bigint;
      }
    ],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "factory"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "getAmountsIn"
  ): TypedContractMethod<
    [amountOut: BigNumberish, path: AddressLike[]],
    [bigint[]],
    "view"
  >;
  getFunction(
    nameOrSignature: "getAmountsOut"
  ): TypedContractMethod<
    [amountIn: BigNumberish, path: AddressLike[]],
    [bigint[]],
    "view"
  >;
  getFunction(
    nameOrSignature: "removeLiquidity"
  ): TypedContractMethod<
    [
      tokenA: AddressLike,
      tokenB: AddressLike,
      liquidity: BigNumberish,
      amountAMin: BigNumberish,
      amountBMin: BigNumberish,
      to: AddressLike,
      deadline: BigNumberish
    ],
    [[bigint, bigint] & { amountA: bigint; amountB: bigint }],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "swapExactTokensForTokens"
  ): TypedContractMethod<
    [
      amountIn: BigNumberish,
      amountOutMin: BigNumberish,
      path: AddressLike[],
      to: AddressLike,
      deadline: BigNumberish
    ],
    [bigint[]],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "swapTokensForExactTokens"
  ): TypedContractMethod<
    [
      amountOut: BigNumberish,
      amountInMax: BigNumberish,
      path: AddressLike[],
      to: AddressLike,
      deadline: BigNumberish
    ],
    [bigint[]],
    "nonpayable"
  >;

  filters: {};
}

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

export interface IEndpointInterface extends Interface {
  getFunction(
    nameOrSignature:
      | "depositCollateral"
      | "depositCollateralWithReferral"
      | "submitSlowModeTransaction"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "depositCollateral",
    values: [BytesLike, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "depositCollateralWithReferral",
    values: [BytesLike, BigNumberish, BigNumberish, string]
  ): string;
  encodeFunctionData(
    functionFragment: "submitSlowModeTransaction",
    values: [BytesLike]
  ): string;

  decodeFunctionResult(
    functionFragment: "depositCollateral",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "depositCollateralWithReferral",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "submitSlowModeTransaction",
    data: BytesLike
  ): Result;
}

export interface IEndpoint extends BaseContract {
  connect(runner?: ContractRunner | null): IEndpoint;
  waitForDeployment(): Promise<this>;

  interface: IEndpointInterface;

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

  depositCollateral: TypedContractMethod<
    [subaccountName: BytesLike, productId: BigNumberish, amount: BigNumberish],
    [void],
    "nonpayable"
  >;

  depositCollateralWithReferral: TypedContractMethod<
    [
      subaccountName: BytesLike,
      productId: BigNumberish,
      amount: BigNumberish,
      referralCode: string
    ],
    [void],
    "nonpayable"
  >;

  submitSlowModeTransaction: TypedContractMethod<
    [transaction: BytesLike],
    [void],
    "nonpayable"
  >;

  getFunction<T extends ContractMethod = ContractMethod>(
    key: string | FunctionFragment
  ): T;

  getFunction(
    nameOrSignature: "depositCollateral"
  ): TypedContractMethod<
    [subaccountName: BytesLike, productId: BigNumberish, amount: BigNumberish],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "depositCollateralWithReferral"
  ): TypedContractMethod<
    [
      subaccountName: BytesLike,
      productId: BigNumberish,
      amount: BigNumberish,
      referralCode: string
    ],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "submitSlowModeTransaction"
  ): TypedContractMethod<[transaction: BytesLike], [void], "nonpayable">;

  filters: {};
}

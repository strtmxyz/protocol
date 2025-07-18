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
} from "../../common";

export interface IHasSupportedAssetInterface extends Interface {
  getFunction(
    nameOrSignature: "getAssetType" | "getSupportedAssets" | "isSupportedAsset"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "getAssetType",
    values: [AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "getSupportedAssets",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "isSupportedAsset",
    values: [AddressLike]
  ): string;

  decodeFunctionResult(
    functionFragment: "getAssetType",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getSupportedAssets",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isSupportedAsset",
    data: BytesLike
  ): Result;
}

export interface IHasSupportedAsset extends BaseContract {
  connect(runner?: ContractRunner | null): IHasSupportedAsset;
  waitForDeployment(): Promise<this>;

  interface: IHasSupportedAssetInterface;

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

  getAssetType: TypedContractMethod<[asset: AddressLike], [bigint], "view">;

  getSupportedAssets: TypedContractMethod<[], [string[]], "view">;

  isSupportedAsset: TypedContractMethod<
    [asset: AddressLike],
    [boolean],
    "view"
  >;

  getFunction<T extends ContractMethod = ContractMethod>(
    key: string | FunctionFragment
  ): T;

  getFunction(
    nameOrSignature: "getAssetType"
  ): TypedContractMethod<[asset: AddressLike], [bigint], "view">;
  getFunction(
    nameOrSignature: "getSupportedAssets"
  ): TypedContractMethod<[], [string[]], "view">;
  getFunction(
    nameOrSignature: "isSupportedAsset"
  ): TypedContractMethod<[asset: AddressLike], [boolean], "view">;

  filters: {};
}

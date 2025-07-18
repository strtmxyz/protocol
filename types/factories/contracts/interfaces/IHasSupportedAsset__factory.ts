/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Interface, type ContractRunner } from "ethers";
import type {
  IHasSupportedAsset,
  IHasSupportedAssetInterface,
} from "../../../contracts/interfaces/IHasSupportedAsset";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "asset",
        type: "address",
      },
    ],
    name: "getAssetType",
    outputs: [
      {
        internalType: "uint16",
        name: "",
        type: "uint16",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "getSupportedAssets",
    outputs: [
      {
        internalType: "address[]",
        name: "",
        type: "address[]",
      },
    ],
    stateMutability: "view",
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
    name: "isSupportedAsset",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

export class IHasSupportedAsset__factory {
  static readonly abi = _abi;
  static createInterface(): IHasSupportedAssetInterface {
    return new Interface(_abi) as IHasSupportedAssetInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): IHasSupportedAsset {
    return new Contract(address, _abi, runner) as unknown as IHasSupportedAsset;
  }
}

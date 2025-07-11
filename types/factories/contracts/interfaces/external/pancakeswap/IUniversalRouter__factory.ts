/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Interface, type ContractRunner } from "ethers";
import type {
  IUniversalRouter,
  IUniversalRouterInterface,
} from "../../../../../contracts/interfaces/external/pancakeswap/IUniversalRouter";

const _abi = [
  {
    inputs: [
      {
        internalType: "bytes",
        name: "commands",
        type: "bytes",
      },
      {
        internalType: "bytes[]",
        name: "inputs",
        type: "bytes[]",
      },
      {
        internalType: "uint256",
        name: "deadline",
        type: "uint256",
      },
    ],
    name: "execute",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
] as const;

export class IUniversalRouter__factory {
  static readonly abi = _abi;
  static createInterface(): IUniversalRouterInterface {
    return new Interface(_abi) as IUniversalRouterInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): IUniversalRouter {
    return new Contract(address, _abi, runner) as unknown as IUniversalRouter;
  }
}

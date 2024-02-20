// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { Buy } from "../../src/Buy.sol";

contract Run is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_PROD");
    vm.startBroadcast(deployerPrivateKey);
    address tn100x = 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A;
    new Buy(5000 ether, tn100x);
  }
}

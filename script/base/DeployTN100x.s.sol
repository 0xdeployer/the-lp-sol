// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TN100x} from "../../src/TN100x.sol";

contract Run is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_PROD");
        vm.startBroadcast(deployerPrivateKey);
        new TN100x();
    }
}
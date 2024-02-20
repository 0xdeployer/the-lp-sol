// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TN100x} from "../../src/TN100x.sol";
import {GoldenHam} from "../../src/GoldenHam.sol";

contract Run is Script {
    function run() external {
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        TN100x tn100x = new TN100x();
        new GoldenHam(vm.readFile("./ham.base64"), block.timestamp + 72 hours, block.timestamp + 45 days, address(tn100x));
    }
}
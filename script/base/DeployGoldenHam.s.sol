// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {GoldenHam} from "../../src/GoldenHam.sol";

contract Run is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_PROD");
        vm.startBroadcast(deployerPrivateKey);
        new GoldenHam(vm.readFile("./ham.base64"), block.timestamp + 72 hours, block.timestamp + 45 days, 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A);
    }
}
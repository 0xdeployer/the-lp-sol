// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { Airdropper } from "../../src/Airdrop.sol";
import { TN100x } from "../../src/TN100x.sol";

contract Run is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_PROD");
    vm.startBroadcast(deployerPrivateKey);
    address tn100x = 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A;
    Airdropper airdropper = new Airdropper(
      bytes32(
        0x635d26303014f4d34faed8487ac044a04632d5590ac902c607f405d95b9eda68
      ),
      tn100x,
      1715702400
    );
    TN100x(tn100x).transfer(address(airdropper), 166_666_667 ether);
  }
}

//166666667
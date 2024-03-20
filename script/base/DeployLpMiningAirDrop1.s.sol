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
        0x0056d4db922c51a8e052f5ae00dfc8529c23a88fe03ad60b34ee43b1acec47ff
      ),
      tn100x
    );
    TN100x(tn100x).transfer(address(airdropper), 166_666_667 ether);
  }
}

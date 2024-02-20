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
        0x33ad4e7d8b0d230b900f5b0cc062c860e9bc968f6140f25dbaa9341b6c4831a5
      ),
      tn100x
    );
    TN100x(tn100x).transfer(address(airdropper), 241_778_413 ether);
  }
}

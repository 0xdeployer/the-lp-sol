// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { TN100x } from "../../src/TN100x.sol";
import { GoldenHam } from "../../src/GoldenHam.sol";
import { TheLP } from "../../src/TheLP.sol";
import { TheLPTraits } from "../../src/TheLPTraits.sol";
import { TheLPRenderer } from "../../src/TheLPRenderer.sol";

contract Run is Script {
  address linear = 0xe41352CB8D9af18231E05520751840559C2a548A;
  address factory = 0x605145D263482684590f630E9e581B21E4938eb8;
  address tn100x = 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_PROD");
    vm.startBroadcast(deployerPrivateKey);
    TheLPTraits traits = new TheLPTraits();
    TheLPRenderer renderer = new TheLPRenderer(traits);
    TheLP lp = new TheLP(
      "The Based LP",
      "BLP",
      // Feb 22 9 AM PT
      1708621200,
      renderer,
      2 days,
      factory,
      linear,
      tn100x
    );
    renderer.setTraitsImage(vm.readFile("./traits.base64"));
    TN100x(tn100x).transfer(address(lp), 1950000000 ether);
  }
}

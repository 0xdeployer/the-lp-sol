// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/TheLp.sol";
import "../src/TheLPTraits.sol";
import "../src/TheLPRenderer.sol";

// 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
// 0x15d34aaf54267db7d7c367839aaf71a00a2c6a65

//0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
//0x90f79bf6eb2c4f870365e785982e1f101e93b906

// Prod values
// TheLP lp = new TheLP(
//   block.timestamp,
//   renderer,
//   0.0333 ether,
//   3.33 ether,
//   8_000,
//   1_000,
//   1_000,
//   11 days,
//   address(this)
// );

contract DeployLP is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);
    TheLPTraits traits = new TheLPTraits();
    TheLPRenderer renderer = new TheLPRenderer(traits);
    TheLP lp = new TheLP(
      block.timestamp,
      renderer,
      0.0333 ether,
      3.33 ether,
      5,
      1,
      1,
      2 days,
      address(this)
    );
    // renderer.setTraitsImage(
    //   "data:image/png;base64,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"
    // );
    vm.stopBroadcast();
    uint256 buyerPrivateKey = vm.envUint("PRIVATE_KEY_B");
    vm.startBroadcast(buyerPrivateKey);
    uint256 price = lp.getCurrentMintPrice();
    lp.mint{ value: price * 5 }(5);
    vm.stopBroadcast();
  }
}

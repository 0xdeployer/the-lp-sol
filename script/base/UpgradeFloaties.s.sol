// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { TN100x } from "../../src/TN100x.sol";
import { Floaties, IFloaties } from "../../src/Floaties.sol";
import { FloatiesProxy } from "../../src/FloatiesProxy.sol";
import { TransparentUpgradeableProxy } from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

contract Run is Script {

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_PROD");
    vm.startBroadcast(deployerPrivateKey);

    Floaties floaties = new Floaties();
    ProxyAdmin admin = ProxyAdmin(0x6468e7bD3EB8D22871c7e529837efA9d9ab60c66);
    admin.upgrade(
      TransparentUpgradeableProxy(
        payable(0x56B10bf5E47C8262569F3119Dfb4bE457795C8a2)
      ),
      address(floaties)
    );
  }
}

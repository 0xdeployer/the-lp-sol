// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { TN100x } from "../../src/TN100x.sol";
import { Oven } from "../../src/Oven.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { OvenProxy } from "../../src/OvenProxy.sol";

contract Run is Script {
  address tn = 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A;
  address lp = 0x8Ce608cE2B5004397fAEF1556bFE33bdFbE4696d;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_PROD");
    vm.startBroadcast(deployerPrivateKey);
    TN100x tn100x = TN100x(tn);
    Oven oven = new Oven();

    ProxyAdmin proxyAdmin = new ProxyAdmin();
    OvenProxy ovenProxy = new OvenProxy(
      address(oven),
      address(proxyAdmin),
      abi.encodeWithSelector(Oven.initialize.selector, tn, lp, 1710345600)
    );
    oven = Oven(address(ovenProxy));
    tn100x.transfer(address(ovenProxy), 1_950_000_000 * 10**18);
  }
}

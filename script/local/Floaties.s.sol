// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { TN100x } from "../../src/TN100x.sol";
import { Floaties, IFloaties } from "../../src/Floaties.sol";
import { FloatiesProxy } from "../../src/FloatiesProxy.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

contract Run is Script {
  address tn100x = 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A;
  address collector = address(69);

  function run() external {
    vm.startBroadcast(
      0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
    );

    Floaties floaties = new Floaties();
    ProxyAdmin proxyAdmin = new ProxyAdmin();
    FloatiesProxy floatyProxy = new FloatiesProxy(
      address(floaties),
      address(proxyAdmin),
      abi.encodeWithSelector(
        Floaties.initialize.selector,
        tn100x,
        collector,
        // $0.25
        250000
      )
    );
    floaties = Floaties(address(floatyProxy));
    address localSigner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    floaties.modifySigner(localSigner, true);
    bytes memory floatyHash = hex"f09fa684";
    uint256 valuePerFloaty = 100 ether;
    floaties.initFloaty(floatyHash, tn100x, valuePerFloaty);
  }
}

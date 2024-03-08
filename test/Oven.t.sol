// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TN100x.sol";
import { Oven } from "../src/Oven.sol";
import { OvenProxy } from "../src/OvenProxy.sol";
import { TheLP } from "../src/TheLP.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

// Fork testing mainnet required
contract OvenTest is Test {
  TN100x public tn100x;
  Oven public oven;

  address tn = 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A;
  address lp = 0x8Ce608cE2B5004397fAEF1556bFE33bdFbE4696d;

  address deployer = 0x16760803046fFa4D05878333B0953bBDDc0C20Cb;
  address other = address(30);

  function setUp() public {
    vm.deal(deployer, 100 ether);
    vm.startPrank(deployer);
    tn100x = TN100x(tn);
    oven = new Oven();

    ProxyAdmin proxyAdmin = new ProxyAdmin();
    OvenProxy ovenProxy = new OvenProxy(
      address(oven),
      address(proxyAdmin),
      abi.encodeWithSelector(
        Oven.initialize.selector,
        tn,
        lp
      )
    );
    oven = Oven(address(ovenProxy));
    tn100x.transfer(address(ovenProxy), 1_950_000_000 * 10 ** 18);
  }

  function testBurn() public {
    console2.log(oven.getBurnAmount(300));
  }
}

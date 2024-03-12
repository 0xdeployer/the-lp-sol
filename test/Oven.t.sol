// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TN100x.sol";
import { Oven } from "../src/Oven.sol";
import { OvenProxy } from "../src/OvenProxy.sol";
import { TheLP } from "../src/TheLP.sol";
import { Test721 } from "../src/mock/Erc721.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

// Fork testing mainnet required
contract OvenTest is Test {
  TN100x public tn100x;
  TheLP public lp721;
  Oven public oven;

  address tn = 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A;
  address lp = 0x8Ce608cE2B5004397fAEF1556bFE33bdFbE4696d;

  address deployer = 0x16760803046fFa4D05878333B0953bBDDc0C20Cb;
  address other = address(30);

  function setUp() public {
    vm.deal(deployer, 100 ether);
    vm.startPrank(deployer);
    // tn100x = TN100x(tn);
    // lp721 = TheLP(payable(lp));
    // oven = new Oven();

    // ProxyAdmin proxyAdmin = new ProxyAdmin();
    // OvenProxy ovenProxy = new OvenProxy(
    //   address(oven),
    //   address(proxyAdmin),
    //   abi.encodeWithSelector(Oven.initialize.selector, tn, lp, block.timestamp)
    // );
    // oven = Oven(address(ovenProxy));
    // tn100x.transfer(address(ovenProxy), 1_950_000_000 * 10**18);
  }

  // function testBurn() public {
  //   for (uint256 i = 1; i < 2000; i++) {
  //     address pranker = lp721.ownerOf(i);
  //     vm.startPrank(pranker);
  //     lp721.setApprovalForAll(address(oven), true);
  //     uint256[] memory tokenIds = new uint256[](1);
  //     tokenIds[0] = i;
  //     oven.burnAndRedeem(tokenIds);
  //   }

  //   // console2.log(oven.getBurnAmount(300));
  // }

  // function testBurnToCompletion() public {
  //   TN100x tn100x = new TN100x();
  //   Test721 test721 = new Test721();
  //   ProxyAdmin proxyAdmin = new ProxyAdmin();
  //   Oven oven = new Oven();
  //   OvenProxy ovenProxy = new OvenProxy(
  //     address(oven),
  //     address(proxyAdmin),
  //     abi.encodeWithSelector(
  //       Oven.initialize.selector,
  //       address(tn100x),
  //       address(test721)
  //     )
  //   );
  //   oven = Oven(address(ovenProxy));
  //   tn100x.transfer(address(ovenProxy), 1_950_000_000 * 10**18);
  //   test721.setApprovalForAll(address(oven), true);
  //   for (uint256 i = 1; i <= 3331; i++) {
  //     uint256[] memory tokenIds = new uint256[](1);
  //     tokenIds[0] = i;
  //     oven.burnAndRedeem(tokenIds);
  //     // console2.log(tn100x.balanceOf(address(ovenProxy)));
  //   }
  //   console2.log(test721.balanceOf(oven.burnAddress()));
  //   // console2.log(oven.getBurnAmount(1));
  // }

  function testStartDate() public {
    TN100x tn100x = new TN100x();
    Test721 test721 = new Test721();
    ProxyAdmin proxyAdmin = new ProxyAdmin();
    Oven oven = new Oven();
    OvenProxy ovenProxy = new OvenProxy(
      address(oven),
      address(proxyAdmin),
      abi.encodeWithSelector(
        Oven.initialize.selector,
        address(tn100x),
        address(test721),
        block.timestamp + 1 days
      )
    );
    oven = Oven(address(ovenProxy));
    tn100x.transfer(address(ovenProxy), 1_950_000_000 * 10**18);
    test721.setApprovalForAll(address(oven), true);
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = 1;
    bool hasStarted = oven.hasStarted();
    assertEq(hasStarted, false);
    vm.expectRevert(Oven.HasNotStarted.selector);
    oven.burnAndRedeem(tokenIds);

    vm.warp(block.timestamp + 1 days);
    hasStarted = oven.hasStarted();
    assertEq(hasStarted, true);
  oven.burnAndRedeem(tokenIds);
    // console2.log(oven.getBurnAmount(1));
  }
}

// forge test --fork-url https://base-mainnet.g.alchemy.com/v2/TJE11PfqHQaUQaRpRlkKfzwt8njReT2D --match-path ./test/Oven.t.sol  -vvv

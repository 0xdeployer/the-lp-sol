// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TN100x.sol";
import { Oven } from "../src/Oven.sol";
import { OvenProxy } from "../src/OvenProxy.sol";
import { TheLP } from "../src/TheLP.sol";
import { Test721 } from "../src/mock/Erc721.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { IPool } from "aerodrome/interfaces/IPool.sol";
import { IRouter } from "aerodrome/interfaces/IRouter.sol";
import { Floaties, IFloaties } from "../src/Floaties.sol";
import { FloatiesProxy } from "../src/FloatiesProxy.sol";

// Fork testing mainnet required
contract FloatiesTest is Test {
  IPool public pool;

  address tn = 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A;
  address weth = 0x4200000000000000000000000000000000000006;
  address _pool = 0x8f5F1D63599362115e7F9fe71BFD5ab883D82c82;
  Floaties floaties;

  address deployer = 0x16760803046fFa4D05878333B0953bBDDc0C20Cb;
  address collector = address(30);
  address signer = address(69);

  address buyer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
  uint256 buyerPrivateKey =
    0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

  function setUp() public {
    vm.deal(deployer, 100 ether);
    vm.startPrank(deployer);
    pool = IPool(_pool);

    floaties = new Floaties();

    ProxyAdmin proxyAdmin = new ProxyAdmin();
    FloatiesProxy floatyProxy = new FloatiesProxy(
      address(floaties),
      address(proxyAdmin),
      abi.encodeWithSelector(
        Floaties.initialize.selector,
        tn,
        collector,
        // $0.25
        250000
      )
    );
    floaties = Floaties(address(floatyProxy));
    floaties.modifySigner(signer, true);
    vm.stopPrank();

    // TN100x(tn).transfer(address(bondIssuer), 7_000_000 ether);
  }

  function testRoute() public {
    IRouter.Route[] memory routes = new IRouter.Route[](1);
    routes[0] = IRouter.Route({
      from: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
      to: 0x4200000000000000000000000000000000000006,
      stable: true,
      factory: address(0)
    });
    uint256[] memory amount = IRouter(
      0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43
    ).getAmountsOut(1000, routes);
    console.log(amount[1]);
  }

  //   function testBuyWithPermit() public {
  //     ERC20 tn100x = ERC20(tn);
  //     vm.startPrank(0x16760803046fFa4D05878333B0953bBDDc0C20Cb);
  //     tn100x.transfer(
  //       buyer,
  //       tn100x.balanceOf(0x16760803046fFa4D05878333B0953bBDDc0C20Cb)
  //     );
  //     vm.stopPrank();

  //     bytes memory floatyHash = "0xf09fa684";
  //     uint256 valuePerFloaty = 100 ether;
  //     vm.prank(deployer);
  //     floaties.initFloaty(floatyHash, tn, valuePerFloaty);
  //     uint256 amountToBuy = 1;
  //     uint256 fee = floaties.calculateFee(1);
  //     uint256 nonce = tn100x.nonces(buyer);
  //     uint256 deadline = block.timestamp + 1 hours;

  //     // Prepare the fee permit message
  //     bytes32 domainSeparator = tn100x.DOMAIN_SEPARATOR();

  //     uint8 tnV;
  //     bytes32 tnR;
  //     bytes32 tnS;

  //     uint8 v;
  //     bytes32 r;
  //     bytes32 s;

  //     {
  //       bytes32 structHash = keccak256(
  //         abi.encode(
  //           keccak256(
  //             "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
  //           ),
  //           buyer,
  //           address(floaties),
  //           fee,
  //           nonce,
  //           deadline
  //         )
  //       );
  //       bytes32 digest = keccak256(
  //         abi.encodePacked("\x19\x01", domainSeparator, structHash)
  //       );

  //       // Sign the digest
  //       (tnV, tnR, tnS) = vm.sign(buyerPrivateKey, digest);
  //     }

  //     {
  //       bytes32 structHash = keccak256(
  //         abi.encode(
  //           keccak256(
  //             "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
  //           ),
  //           buyer,
  //           address(floaties),
  //           valuePerFloaty,
  //           nonce + 1,
  //           deadline
  //         )
  //       );
  //       bytes32 digest = keccak256(
  //         abi.encodePacked("\x19\x01", domainSeparator, structHash)
  //       );

  //       // Sign the digest
  //       (v, r, s) = vm.sign(buyerPrivateKey, digest);
  //     }

  //     IFloaties.BuyWithPermitArgs memory args = IFloaties.BuyWithPermitArgs({
  //       floatyHash: floatyHash,
  //       floatyAmount: 1,
  //       totalCost: valuePerFloaty,
  //       deadline: deadline,
  //       v: v,
  //       r: r,
  //       s: s,
  //       tnFee: fee,
  //       tnDeadline: deadline,
  //       tnV: tnV,
  //       tnR: tnR,
  //       tnS: tnS
  //     });

  //     uint256 balanceBeforePurchase = tn100x.balanceOf(buyer);
  //     vm.prank(buyer);
  //     floaties.buyWithPermit(args);
  //     uint256 balanceAfterPurchase = tn100x.balanceOf(buyer);
  //     assertEq(
  //       balanceBeforePurchase - balanceAfterPurchase == valuePerFloaty + fee,
  //       true
  //     );
  //     uint256 floatyBalance = floaties.balanceOf(buyer, floatyHash);
  //     assertEq(floatyBalance, 1);

  //     address receiver = address(120);
  //     vm.prank(signer);
  //     floaties.spend(buyer, receiver, "1234", floatyHash, 1);

  //     uint balanceOfReceiver = tn100x.balanceOf(receiver);
  //     assertEq(balanceOfReceiver, 100 ether);

  //     floatyBalance = floaties.balanceOf(buyer, floatyHash);
  //     assertEq(floatyBalance, 0);

  //     vm.startPrank(signer);
  //     vm.expectRevert(Floaties.MessageAlreadyPaid.selector);
  //     floaties.spend(buyer, receiver, "1234", floatyHash, 1);
  //     vm.stopPrank();
  //   }

  //     function testBuyWithApproval() public {
  //     ERC20 tn100x = ERC20(tn);
  //     vm.startPrank(0x16760803046fFa4D05878333B0953bBDDc0C20Cb);
  //     TN100x otherCoin = new TN100x();
  //     otherCoin.transfer(buyer, 100 ether);
  //     tn100x.transfer(
  //       buyer,
  //       tn100x.balanceOf(0x16760803046fFa4D05878333B0953bBDDc0C20Cb)
  //     );
  //     vm.stopPrank();

  //     bytes memory floatyHash = "poopie";
  //     uint256 valuePerFloaty = 1 ether;
  //     vm.prank(deployer);
  //     floaties.initFloaty(floatyHash, address(otherCoin), valuePerFloaty);
  //     uint256 amountToBuy = 100;
  //     uint256 fee = floaties.calculateFee(amountToBuy);
  //     uint256 nonce = tn100x.nonces(buyer);
  //     uint256 deadline = block.timestamp + 1 hours;
  //     // Prepare the fee permit message
  //     bytes32 domainSeparator = tn100x.DOMAIN_SEPARATOR();

  //       bytes32 structHash = keccak256(
  //         abi.encode(
  //           keccak256(
  //             "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
  //           ),
  //           buyer,
  //           address(floaties),
  //           fee,
  //           nonce,
  //           deadline
  //         )
  //       );
  //       bytes32 digest = keccak256(
  //         abi.encodePacked("\x19\x01", domainSeparator, structHash)
  //       );

  //       // Sign the digest
  //       (uint8 tnV, bytes32 tnR, bytes32 tnS) = vm.sign(buyerPrivateKey, digest);

  //     uint256 balanceBeforePurchase = tn100x.balanceOf(buyer);
  //     vm.prank(buyer);
  //     otherCoin.approve(address(floaties), 100 ether);
  //     vm.prank(buyer);
  //     floaties.buyWithApproval(floatyHash, amountToBuy, 100 ether, fee, deadline, tnV, tnR, tnS);
  //     uint256 balanceAfterPurchase = tn100x.balanceOf(buyer);
  //     assertEq(
  //       balanceBeforePurchase - balanceAfterPurchase == fee,
  //       true
  //     );
  //     uint balanceOfOtherToken = otherCoin.balanceOf(buyer);
  //     assertEq(balanceOfOtherToken, 0);

  //     uint256 floatyBalance = floaties.balanceOf(buyer, floatyHash);
  //     assertEq(floatyBalance, amountToBuy);

  //     address receiver = address(120);
  //     vm.prank(signer);
  //     floaties.spend(buyer, receiver, "1234", floatyHash, amountToBuy);

  //     uint balanceOfReceiver = otherCoin.balanceOf(receiver);
  //     assertEq(balanceOfReceiver, 100 ether);

  //     floatyBalance = floaties.balanceOf(buyer, floatyHash);
  //     assertEq(floatyBalance, 0);

  //     vm.startPrank(signer);
  //     vm.expectRevert(Floaties.MessageAlreadyPaid.selector);
  //     floaties.spend(buyer, receiver, "1234", floatyHash, amountToBuy);
  //     vm.stopPrank();
  //   }
}

// forge test --fork-url https://base-mainnet.g.alchemy.com/v2/TJE11PfqHQaUQaRpRlkKfzwt8njReT2D --match-path ./test/Bond.t.sol  -vvv

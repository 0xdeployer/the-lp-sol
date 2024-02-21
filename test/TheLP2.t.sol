// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TheLP.sol";
import "../src/TheLPTraits.sol";
import "../src/TheLPRenderer.sol";
import "solmate/utils/LibString.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import { LSSVMPair } from "lssvm2/LSSVMPair.sol";

// forge test --fork-url https://base-mainnet.g.alchemy.com/v2/TJE11PfqHQaUQaRpRlkKfzwt8njReT2D --match-path ./test/TheLP2.t.sol -vvv

contract TheLPTest is Test {
  TheLP public lp;
  TheLPRenderer public renderer;
  using LibString for uint256;
  TheLPTraits traits;

  address deployer = address(1);
  address minter = address(2);
  address buyer = address(3);
  address linear = 0xe41352CB8D9af18231E05520751840559C2a548A;
  address factory = 0x605145D263482684590f630E9e581B21E4938eb8;

  function setUp() public {
    traits = new TheLPTraits();
    renderer = new TheLPRenderer(traits);
    vm.prank(deployer);
    lp = new TheLP(
      "The Based LP",
      "BLP",
      block.timestamp,
      renderer,
      // Should this be 3 days? I had 12 days in original contract but it was 11
      2 days,
      deployer,
      factory,
      linear
    );
    renderer.setTraitsImage(vm.readFile("./traits.base64"));
  }

  function testShouldBeAbleToMintUpTo2daysButNotAfter() public {
    vm.deal(minter, 100 ether);
    vm.warp(block.timestamp + 2 days);
    vm.startPrank(minter);
    uint256 mintPrice = lp.getCurrentMintPrice();
    assertEq(mintPrice - 0.001 ether < 50000, true);
    lp.mint{ value: mintPrice }(1);
    vm.warp(block.timestamp + 1 days);
    mintPrice = lp.getCurrentMintPrice();
    vm.expectRevert(TheLP.AuctionEnded.selector);
    lp.mint{ value: mintPrice }(1);
  }

  function testShouldBeAbleToWithdrawAfterGameOver() public {
    vm.deal(minter, 100 ether);
    vm.startPrank(minter);
    uint256 mintPrice = lp.getCurrentMintPrice();
    lp.mint{ value: mintPrice }(1);
    uint256 balanceAfterMint = minter.balance;
    uint256 ownedToken = lp.tokensOfOwner(minter)[0];

    vm.warp(block.timestamp + 2.01 days);
    uint256[] memory ids = new uint256[](1);
    ids[0] = ownedToken;
    lp.redeem(ids);
    uint256 balanceAfterRedeem = minter.balance;
    assertEq(balanceAfterRedeem - balanceAfterMint, mintPrice);

    // claiming again should fail
    vm.expectRevert(
      abi.encodeWithSelector(TheLP.InvalidTokenId.selector, ownedToken)
    );
    lp.redeem(ids);
  }

  function testShouldClaimDeltaBetweenMintPriceAndFinalPrice() public {
    vm.deal(minter, 100 ether);
    vm.startPrank(minter);
    uint256 mintPrice = lp.getCurrentMintPrice();
    lp.mint{ value: mintPrice }(1);
    vm.stopPrank();

    address minter2 = address(69);
    vm.deal(minter2, 100 ether);
    vm.warp(block.timestamp + 2 days);
    vm.startPrank(minter2);
    lp.mint{ value: 50 ether }(2900 - 1);
    vm.stopPrank();

    uint256 finalPrice = lp.finalCost();
    uint256 delta = mintPrice - finalPrice;
    uint256 ownedToken = lp.tokensOfOwner(minter)[0];
    uint256[] memory ids = new uint256[](1);
    ids[0] = ownedToken;
    uint256 balanceBeforeRefund = minter.balance;
    vm.startPrank(minter);
    lp.claimRefund(ids);

    uint256 balanceAfterRefund = minter.balance;
    assertEq(balanceAfterRefund - balanceBeforeRefund, delta);
  }

  function testShouldClaimDeltaBetweenMintPriceAndFinalPriceWhenMintingMany()
    public
  {
    vm.deal(minter, 100 ether);
    vm.startPrank(minter);
    uint256 mintPrice = lp.getCurrentMintPrice();
    uint256 amount = 30;
    lp.mint{ value: mintPrice * amount }(amount);
    vm.stopPrank();

    address minter2 = address(69);
    vm.deal(minter2, 100 ether);
    vm.warp(block.timestamp + 2 days);
    vm.startPrank(minter2);
    lp.mint{ value: 50 ether }(2900 - amount);
    vm.stopPrank();

    uint256 finalPrice = lp.finalCost();
    uint256 delta = (mintPrice - finalPrice) * amount;
    uint256[] memory ownedTokens = lp.tokensOfOwner(minter);
    uint256 balanceBeforeRefund = minter.balance;
    vm.startPrank(minter);
    lp.claimRefund(ownedTokens);

    uint256 balanceAfterRefund = minter.balance;
    assertEq(balanceAfterRefund - balanceBeforeRefund, delta);
    vm.stopPrank();

    // should be able to init pool with specified ETH
    vm.prank(deployer);
    lp.initSudoPool();
  }

  function testProperlyDistributeProceeds() public {
    uint256 balanceBeforeAllSold = deployer.balance;
    vm.deal(minter, 800 ether);
    vm.startPrank(minter);
    uint256 mintPrice = lp.getCurrentMintPrice();
    uint256 amount = 2900;
    lp.mint{ value: mintPrice * amount }(amount);
    vm.stopPrank();
    uint256 balanceAfterAllSold = deployer.balance;
    uint256 delta = balanceAfterAllSold - balanceBeforeAllSold;
    uint256 amountToSudo = 100 * 0.25 ether;
    uint256 totalAmount = 2900 * 0.25 ether;
    assertEq(delta, totalAmount - amountToSudo);
    vm.prank(deployer);
    lp.initSudoPool();
    assertEq(lp.tradePool().balance, amountToSudo);
    bool isGameOver = lp.isGameOver();
    assertEq(isGameOver, false);
  }

  function testMetadata() public {
    vm.deal(minter, 800 ether);
    vm.startPrank(minter);
    uint256 mintPrice = lp.getCurrentMintPrice();
    uint256 amount = 2900;
    lp.mint{ value: mintPrice * amount }(amount);
    vm.stopPrank();
    bool lockedIn = lp.lockedIn();
    assertEq(lockedIn, true);
    for(uint i = 0; i < 10; i++) {
        vm.writeFile(string.concat("./meta", i.toString()), lp.tokenURI(i + 1));
    }

  }


  //   function testShouldTrendDownwardInPrice() public {
  //     vm.warp(block.timestamp + 2 days);
  //     console2.log(lp.getCurrentMintPrice());
  //     vm.deal(minter, 100 ether);
  //     vm.prank(minter);
  //     lp.mint{ value: 50 ether }(2900);

  //     vm.prank(deployer);
  //     lp.initSudoPool();

  //     uint256[] memory ids = new uint256[](1);
  //     uint256 nft = 3234;
  //     ids[0] = nft;
  //     vm.deal(buyer, 2 ether);
  //     vm.startPrank(buyer);

  //     LSSVMPair pair = LSSVMPair(lp.tradePool());

  //     pair.swapTokenForSpecificNFTs{ value: 0.003 ether }(
  //       ids,
  //       0.003 ether,
  //       buyer,
  //       false,
  //       address(0)
  //     );

  //     lp.claim(3234);
  //     console2.log(lp.calculatePendingPayment(3234));
  //     console2.log(lp.calculatePendingPayment(3333));

  // ids[0] = nft + 1;
  //      pair.swapTokenForSpecificNFTs{ value: 0.004 ether }(
  //       ids,
  //       0.004 ether,
  //       buyer,
  //       false,
  //       address(0)
  //     );

  //       console2.log(lp.calculatePendingPayment(3234));
  //     console2.log(lp.calculatePendingPayment(3333));

  //     // lp.setApprovalForAll(address(pair), true);

  //     // pair.swapNFTsForToken(ids, 0, payable(buyer), false, address(0));

  //     // lp.claim(nft);
  //   }
}

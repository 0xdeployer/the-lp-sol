// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { GoldenHam } from "../src/GoldenHam.sol";
import { TN100x } from "../src/TN100x.sol";

contract GoldenHamTest is Test {
  GoldenHam public gh;
  TN100x public tn100x;

  address deployer = address(20);
  address other = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
  uint256 otherPrivateKey =
    0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
  address other2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
  uint256 other2PrivateKey =
    0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

  function setUp() public {
    vm.deal(deployer, 100 ether);
    vm.startPrank(deployer);
    tn100x = new TN100x();
    gh = new GoldenHam(
      vm.readFile("./ham.base64"),
      block.timestamp + 72 hours,
      block.timestamp + 45 days,
      address(tn100x)
    );
    tn100x.transfer(other, 1_000_000 ether);
    tn100x.transfer(other2, 2_000_000 ether);
    vm.stopPrank();
  }

  function testMintHappyPath() public {
    vm.startPrank(other);
    uint256 nonce = tn100x.nonces(other);
    uint256 deadline = block.timestamp + 1 hours;
    uint256 value = 1_000_000 ether;
    // Prepare the permit message
    bytes32 domainSeparator = tn100x.DOMAIN_SEPARATOR();
    bytes32 structHash = keccak256(
      abi.encode(
        keccak256(
          "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        ),
        other,
        address(gh),
        value,
        nonce,
        deadline
      )
    );
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, structHash)
    );

    // Sign the digest
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(otherPrivateKey, digest);

    gh.mint(value, deadline, v, r, s);
    vm.stopPrank();

    vm.startPrank(other2);

    nonce = tn100x.nonces(other2);
    deadline = block.timestamp + 1 hours;
    value = 2_000_000 ether;
    // Prepare the permit message
    domainSeparator = tn100x.DOMAIN_SEPARATOR();
    structHash = keccak256(
      abi.encode(
        keccak256(
          "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        ),
        other2,
        address(gh),
        value,
        nonce,
        deadline
      )
    );
    digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, structHash)
    );

    // Sign the digest
    (v, r, s) = vm.sign(other2PrivateKey, digest);

    gh.mint(value, deadline, v, r, s);

    vm.stopPrank();

    uint256 totalLocked = gh.totalLocked();
    assertEq(totalLocked, 3_000_000 ether);

    uint256 lockedForToken1 = gh.tokenIdToAmountLocked(1);
    assertEq(lockedForToken1, 1_000_000 ether);

    uint256 lockedForToken2 = gh.tokenIdToAmountLocked(2);
    assertEq(lockedForToken2, 2_000_000 ether);
  }

  function getSig(
    address sender,
    uint256 privateKey,
    uint256 value
  )
    public
    returns (
      uint256,
      uint8,
      bytes32,
      bytes32
    )
  {
    uint256 nonce = tn100x.nonces(sender);
    uint256 deadline = block.timestamp + 1 hours;

    // Prepare the permit message
    bytes32 domainSeparator = tn100x.DOMAIN_SEPARATOR();
    bytes32 structHash = keccak256(
      abi.encode(
        keccak256(
          "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        ),
        sender,
        address(gh),
        value,
        nonce,
        deadline
      )
    );
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, structHash)
    );

    // Sign the digest
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
    return (deadline, v, r, s);
  }

  function testShouldThrowWhenTryingToMintAfterMintEnd() public {
    vm.startPrank(other);
    vm.warp(block.timestamp + 72.5 hours);
    (uint256 deadline, uint8 v, bytes32 r, bytes32 s) = getSig(
      other,
      otherPrivateKey,
      1_000_000 ether
    );
    vm.expectRevert(GoldenHam.MintEnded.selector);
    gh.mint(1_000_000 ether, deadline, v, r, s);
  }

  //   function testShouldRequireAnAmountGtZero() public {
  //     vm.startPrank(other);
  //     tn100x.approve(address(gh), 1_000_000 ether);
  //     vm.expectRevert(GoldenHam.InvalidAmount.selector);
  //     gh.mint(0);
  //   }

  //   function testShouldReturnAmountStakedForNFT() public {
  //     vm.startPrank(other);
  //     tn100x.approve(address(gh), 1_000_000 ether);
  //     gh.mint(1_000_000 ether);
  //     vm.stopPrank();

  //     uint256 lockedForToken1 = gh.tokenIdToAmountLocked(1);
  //     assertEq(lockedForToken1, 1_000_000 ether);
  //   }

  //   function testShouldAllowWithdrawAfterEndPeriod() public {
  //     vm.startPrank(other);
  //     tn100x.approve(address(gh), 1_000_000 ether);
  //     gh.mint(500_000 ether);
  //     gh.mint(500_000 ether);

  //     vm.warp(block.timestamp + 45.5 days);
  //     assertEq(tn100x.balanceOf(other), 0);
  //     uint256[] memory ids = new uint256[](2);
  //     ids[0] = 1;
  //     ids[1] = 2;
  //     gh.withdraw(ids);
  //     assertEq(tn100x.balanceOf(other), 1_000_000 ether);
  //     vm.stopPrank();
  //   }

  //   function testShouldThrowWhenNotOwner() public {
  //     vm.startPrank(other);
  //     tn100x.approve(address(gh), 1_000_000 ether);
  //     gh.mint(500_000 ether);
  //     gh.mint(500_000 ether);
  //     vm.stopPrank();
  //     vm.warp(block.timestamp + 45.5 days);
  //     assertEq(tn100x.balanceOf(other), 0);
  //     uint256[] memory ids = new uint256[](2);
  //     ids[0] = 1;
  //     ids[1] = 2;
  //     vm.prank(other2);
  //     vm.expectRevert(GoldenHam.NotOwner.selector);
  //     gh.withdraw(ids);
  //   }

  //   function testShouldThrowWhenTryingToWithdrawBeforeEndDate() public {
  //     vm.startPrank(other);
  //     tn100x.approve(address(gh), 1_000_000 ether);
  //     gh.mint(500_000 ether);
  //     uint256[] memory ids = new uint256[](1);
  //     ids[0] = 1;
  //     vm.expectRevert(GoldenHam.LockingPeriodNotEnded.selector);
  //     gh.withdraw(ids);
  //   }

  //   function testShouldThrowWhenNonOwnerTryingToUpdateMintEndDate() public {
  //     vm.startPrank(other);
  //     vm.expectRevert();
  //     gh.updateMintEndDate(0);
  //     vm.stopPrank();
  //   }

  //   function testShouldUpdateMintEndDate() public {
  //     vm.startPrank(deployer);
  //     gh.updateMintEndDate(0);
  //     assertEq(gh.mintEndDate(), 0);
  //     vm.stopPrank();
  //   }

  //   function testShouldThrowWhenNonOwnerTryingToUpdateLockingEndDate() public {
  //     vm.startPrank(other);
  //     vm.expectRevert();
  //     gh.updateLockingPeriodEndDate(0);
  //     vm.stopPrank();
  //   }

  function testMetadata() public {
    vm.startPrank(other);
    uint256 nonce = tn100x.nonces(other);
    uint256 deadline = block.timestamp + 1 hours;
    uint256 value = 1_000_000 ether;
    // Prepare the permit message
    bytes32 domainSeparator = tn100x.DOMAIN_SEPARATOR();
    bytes32 structHash = keccak256(
      abi.encode(
        keccak256(
          "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        ),
        other,
        address(gh),
        value,
        nonce,
        deadline
      )
    );
    bytes32 digest = keccak256(
      abi.encodePacked("\x19\x01", domainSeparator, structHash)
    );

    // Sign the digest
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(otherPrivateKey, digest);

    gh.mint(value, deadline, v, r, s);

    console2.log(gh.tokenURI(1));
  }
}

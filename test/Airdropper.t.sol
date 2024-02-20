// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { GoldenHam } from "../src/GoldenHam.sol";
import { TN100x } from "../src/TN100x.sol";
import { Airdropper } from "../src/Airdrop.sol";

contract AirdropperTest is Test {
  Airdropper public airdrop;
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
    airdrop = new Airdropper(
      bytes32(
        0x9109094ed51161cbd1236594a64ae8febcc93add1bb8406b0ac78b51457b2889
      ),
      address(tn100x)
    );
    tn100x.transfer(address(airdrop), 250_000_000 ether);
    tn100x.transfer(other, 1_000_000 ether);
    tn100x.transfer(other2, 2_000_000 ether);
    vm.stopPrank();
  }

  function testClaim() public {
    address claimer = 0xb585b60De71E48032e8C19B90896984afc6a660d;
    vm.deal(claimer, 100 ether);
    vm.startPrank(claimer);
    bytes32[] memory proof = new bytes32[](11);
    proof[0] = bytes32(
      0xf076732b986b04736ebaf9fedd1aedc9d5081986c09ce84946246a1f5613398e
    );
    proof[1] = bytes32(
      0xfb5bd2b6d7ee8b6a788c35f887fb5ea5628bba127c99d3f116ee13547ee9afa1
    );
    proof[2] = bytes32(
      0x704455a54ea21137a3bc91b3175324818442cf43e169e97f500b27e803ef269d
    );
    proof[3] = bytes32(
      0x40391045c006b2a71d89345eda123fd37f173475839bb93079d460393ac71b67
    );
    proof[4] = bytes32(
      0x323cc5080c03f1172050e15bbf9c808bdf233ae5628f10fdf2594bd45f80ecf2
    );
    proof[5] = bytes32(
      0x26edc5c2231ab52d11bf5bc7a5a409f268ee5d3730050b959451b25f54f3a34a
    );
    proof[6] = bytes32(
      0x4013d39785660e2cdab9cfc4ba886807398afaee78dfd1e65b8c4926e0471a13
    );
    proof[7] = bytes32(
      0x8c4b811011a7e67b1aa11c6398ebbb20ecad2099591048509fa80bd9c8fb6399
    );
    proof[8] = bytes32(
      0x576d96c3f45da835db1040393d02eacb038bc6396e1a224884b4c803377f0db6
    );
    proof[9] = bytes32(
      0x16a9aef992f153510d3767d6994d1bf6d8c23d98490ec2d95da7aa7742f312d3
    );
    proof[10] = bytes32(
      0x1b1b542c3a0146f05daa7ea7c9784c7ea982c4063e94a4726ed9dd3834c29c35
    );


    airdrop.claim(1088929 ether, proof);

    assertEq(tn100x.balanceOf(claimer), 1088929 ether);

    vm.expectRevert(Airdropper.HasClaimed.selector);
    airdrop.claim(1088929 ether, proof);
    vm.stopPrank();
  }

  function testWithdraw() public {
    vm.startPrank(deployer);
    address wallet =address(1);
    airdrop.withdraw(wallet);
    assertEq(tn100x.balanceOf(wallet), 250_000_000 ether);
  }
}

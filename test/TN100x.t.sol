// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TN100x.sol";

contract TN100xTest is Test {
    TN100x public tn100x;

    address deployer = address(20);
    address other = address(30);

    function setUp() public {
        vm.deal(deployer, 100 ether);
        vm.startPrank(deployer);
        tn100x = new TN100x();
    }

    function testInitialMint() public {
        assertEq(tn100x.balanceOf(deployer), 10_000_000_000 * 10 ** 18);
        tn100x.transfer(other, 1_000_000 ether);
        assertEq(tn100x.balanceOf(other), 1_000_000 ether);
    }
}

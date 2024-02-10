// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TN100x.sol";

contract CounterTest is Test {
    TN100x public tn100x;

    address deployer = address(20);

    function setUp() public {
        vm.deal(100 ether, deployer);
        vm.prank(deployer);
        tn100x = new TN100x();
    }

    function testInitialMint() public {
        assertEq(tn100x.balanceOf(deployer), 10_000_000_000 * 10 ** 18);
    }
}

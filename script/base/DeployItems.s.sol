// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../../src/Items.sol";

contract Run is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_PROD");
        vm.startBroadcast(deployerPrivateKey);
        Items items = new Items();
        items.addSigner(0xe4B40421ffc42CB3f0d191809b62e6DF7c5Ba08F);
        uint256[] memory numberAttributeValues = new uint[](0);
        string[] memory stringAttributeValues = new string[](1);
        string[] memory numberAttributeKeys = new string[](0);
        string[] memory stringAttributeKeys = new string[](1);

        stringAttributeValues[0] = "Purple Ham";
        stringAttributeKeys[0] = "Name";
        items.initItem(
            "Purple Ham",
            "The Purple Ham was earned by victoriously defeating The Big LP in the special Heroes/LP cross over gaming event.",
            "https://arweave.net/CybEQQtA82-n436fPC9QL3vEic8EG14adNdYka887RM",
            99999999999,
            numberAttributeValues,
            stringAttributeValues,
            numberAttributeKeys,
            stringAttributeKeys
        );
    }
}

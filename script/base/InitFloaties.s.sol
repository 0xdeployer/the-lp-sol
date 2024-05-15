// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { TN100x } from "../../src/TN100x.sol";
import { Floaties, IFloaties } from "../../src/Floaties.sol";
import { FloatiesProxy } from "../../src/FloatiesProxy.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

contract Run is Script {
  address tn100x = 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A;
  address collector = 0x9272EC308F8dbC26eD3a8f3aE16db2F84BF0527c;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_PROD");
    vm.startBroadcast(deployerPrivateKey);

    Floaties floaties = Floaties(0x56B10bf5E47C8262569F3119Dfb4bE457795C8a2);

  // HUNT
    // {
    //   bytes memory emojiHash = hex"f09fa7b1";
    //   uint256 valuePerEmoji = 1 ether;
    //   floaties.initFloaty(
    //     emojiHash,
    //     0x37f0c2915CeCC7e977183B8543Fc0864d03E064C,
    //     valuePerEmoji
    //   );
    // }

    // japan
    {
      bytes memory emojiHash = hex"f09f87aff09f87b5";
      uint256 valuePerEmoji = 10 ether;
      floaties.initFloaty(
        emojiHash,
        0xeF6dd3F0bE6f599e7BcA38b47dB638D5a749CF9C,
        valuePerEmoji
      );
    }

     {
      bytes memory emojiHash = hex"f09f8d94";
      uint256 valuePerEmoji = 69 ether;
      floaties.initFloaty(
        emojiHash,
        0x6776caCcFDCD0dFD5A38cb1D0B3b39A4Ca9283cE,
        valuePerEmoji
      );
    }
  }
}


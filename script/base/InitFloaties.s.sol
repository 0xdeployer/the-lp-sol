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

    // animated 0xe29eb0
    {
      bytes memory emojiHash = hex"e29eb0";
      uint256 valuePerEmoji = 690 ether;
      floaties.initFloaty(
        emojiHash,
        0xDdf98aad8180c3E368467782CD07AE2E3E8d36A5,
        valuePerEmoji
      );
    }

// bleu 0xf09f9098
     {
      bytes memory emojiHash = hex"f09f9098";
      uint256 valuePerEmoji = 690 ether;
      floaties.initFloaty(
        emojiHash,
        0xBf4Db8b7A679F89Ef38125d5F84dd1446AF2ea3B,
        valuePerEmoji
      );
    }
  }
}


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

    // pizza 0xf09f8d95
    // 0x40468be13c4388D2AB68a09F56973fa95DB5bca0
    // 10 ether

    // send it 0xe28697efb88e
    // 0xba5b9b2d2d06a9021eb3190ea5fb0e02160839a4
    // 10 ether

    // dino 0xf09fa696
    // 0x469FdA1FB46Fcb4BeFc0D8B994B516bD28c87003
    // 0.0001 ether

  // higher 
  // 0xe2ac86efb88f
  // 0x0578d8A44db98B23BF096A382e016e29a5Ce0ffe

  // lower
  // 0xe2ac87efb88f
  // 0x67040BB0aD76236DdD5d156D23Ec920A089d1eac

// rawr f09fa696
// virtual f09fa496
// shaka f09fa499

  // nog
    // {
    //   bytes memory emojiHash = hex"e28c90e297a82de297a8";
    //   uint256 valuePerEmoji = 1_000_000 ether;
    //   floaties.initFloaty(
    //     emojiHash,
    //     0x13741C5dF9aB03E7Aa9Fb3Bf1f714551dD5A5F8a,
    //     valuePerEmoji
    //   );
    // }


        {
      bytes memory emojiHash = hex"f09f90b1";
      uint256 valuePerEmoji = 100000 ether;
      floaties.initFloaty(
        emojiHash,
        0xF6e932Ca12afa26665dC4dDE7e27be02A7c02e50,
        valuePerEmoji
      );
    }

  //     [toHex("🐱")]: {
  //   token: "$MOCHI",
  //   contract: "0xF6e932Ca12afa26665dC4dDE7e27be02A7c02e50",
  //   amount: 100000,
  // },


  }
}


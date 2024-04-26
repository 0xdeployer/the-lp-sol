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



    // usdc
    {
      bytes memory emojiHash = hex"f09f92a8";
      uint256 valuePerEmoji = 10000 ether;
      floaties.initFloaty(
        emojiHash,
        0xd7D919Ea0c33A97ad6e7BD4F510498e2ec98Cb78,
        valuePerEmoji
      );
    }
  }
}

/*
0xf09f8d8c
  [toHex("🍌")]: {
    token: "$BANANAS",
    contract: "0x9A27C6759A6de0F26Ac41264f0856617DeC6bC3F",
    amount: 100,
  },

  0xe29da4efb88f
  [toHex("❤️")]: {
    token: "$L2VE",
    contract: "0xA19328fb05ce6FD204D16c2a2A98F7CF434c12F4",
    amount: 690,
  },

  0xf09f9983
  [toHex("🙃")]: {
    token: "$DUH",
    contract: "0x8011eef8FC855Df1c4f421443f306E19818e60D3",
    amount: 69,
  },

  0xf09f98bc
  [toHex("😼")]: {
    token: "$TOSHI",
    contract: "0xac1bd2486aaf3b5c0fc3fd868558b082a531b2b4",
    amount: 420,
  },

  0xf09f92a8
  [toHex("💨")]: {
    token: "$PEN",
    contract: "0xd7D919Ea0c33A97ad6e7BD4F510498e2ec98Cb78",
    amount: 100000,
  },
*/
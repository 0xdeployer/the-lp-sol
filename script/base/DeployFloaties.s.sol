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

    Floaties floaties = new Floaties();
    ProxyAdmin proxyAdmin = new ProxyAdmin();
    FloatiesProxy floatyProxy = new FloatiesProxy(
      address(floaties),
      address(proxyAdmin),
      abi.encodeWithSelector(
        Floaties.initialize.selector,
        tn100x,
        collector,
        // $0.034
        34000
      )
    );
    floaties = Floaties(address(floatyProxy));
    floaties.modifySigner(0x8032DA69F1f80eA3810b3E7b12AbF98D8fc2b1A8, true);
    bytes memory floatyHash = hex"f09fa684";
    uint256 valuePerFloaty = 100 ether;
    floaties.initFloaty(floatyHash, tn100x, valuePerFloaty);

    bytes memory degenHash = hex"f09f8ea9";
    uint256 valuePerDegenFloaty = 10 ether;
    floaties.initFloaty(
      degenHash,
      0x4ed4E862860beD51a9570b96d89aF5E1B0Efefed,
      valuePerDegenFloaty
    );

    bytes memory donutHash = hex"f09f8da9";
    uint256 valuePerDonut = 10 ether;
    floaties.initFloaty(donutHash, tn100x, valuePerDonut);

    bytes memory tybgHash = hex"f09fa791f09f8fbbe2808df09fa6b2";
    uint256 valuePerTybg = 10 ether;
    floaties.initFloaty(
      tybgHash,
      0x0d97F261b1e88845184f678e2d1e7a98D9FD38dE,
      valuePerTybg
    );

    bytes memory gloomHash = hex"f09f91bd";
    uint256 valuePerGloom = 10 ether;
    floaties.initFloaty(
      gloomHash,
      0x4Ff77748E723f0d7B161f90B4bc505187226ED0D,
      valuePerGloom
    );

    bytes memory memberHash = hex"f09f8d86";
    uint256 valuePerMember = 10 ether;
    floaties.initFloaty(
      memberHash,
      0x7d89E05c0B93B24B5Cb23A073E60D008FEd1aCF9,
      valuePerMember
    );
  }
}

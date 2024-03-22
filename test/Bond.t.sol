// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TN100x.sol";
import { Oven } from "../src/Oven.sol";
import { OvenProxy } from "../src/OvenProxy.sol";
import { TheLP } from "../src/TheLP.sol";
import { Test721 } from "../src/mock/Erc721.sol";
import { ProxyAdmin } from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { IPool } from "aerodrome/interfaces/IPool.sol";
import { IRouter } from "aerodrome/interfaces/IRouter.sol";
import { Tn100xBondIssuer } from "../src/Bond.sol";
import { BondProxy } from "../src/BondProxy.sol";

// Fork testing mainnet required
contract BondTest is Test {
  IPool public pool;

  address tn = 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A;
  address weth = 0x4200000000000000000000000000000000000006;
  address _pool = 0x8f5F1D63599362115e7F9fe71BFD5ab883D82c82;
  Tn100xBondIssuer bondIssuer;

  address deployer = 0x16760803046fFa4D05878333B0953bBDDc0C20Cb;
  address other = address(30);

  function setUp() public {
    vm.deal(deployer, 100 ether);
    vm.startPrank(deployer);
    pool = IPool(_pool);

    bondIssuer = new Tn100xBondIssuer();

    ProxyAdmin proxyAdmin = new ProxyAdmin();
    BondProxy bondProxy = new BondProxy(
      address(bondIssuer),
      address(proxyAdmin),
      abi.encodeWithSelector(
        Tn100xBondIssuer.initialize.selector,
        tn,
        _pool,
        weth
      )
    );
    bondIssuer = Tn100xBondIssuer(address(bondProxy));
    TN100x(tn).transfer(address(bondIssuer), 7_000_000 ether);
  }

  function testQuote() public {
    // uint256[] memory quote = pool.sample(weth, 1e18, 1, 1);
    bondIssuer.buy{ value: 0.25 ether }();
    bondIssuer.bonds(1);
  }

  function testRouter() public {
    IRouter.Route[] memory routes = new IRouter.Route[](2);
    routes[0] = IRouter.Route({
      from: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
      to: 0x4200000000000000000000000000000000000006,
      stable: true,
      factory: address(0)
    });
    routes[1] = IRouter.Route({
      from: 0x4200000000000000000000000000000000000006,
      to: 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A,
      stable: false,
      factory: address(0)
    });
    uint[] memory amount = IRouter(0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43).getAmountsOut(
      250000,
      routes
    );
    console2.log(amount[0]);
    console2.log(amount[1]);
    console2.log(amount[2]);
  }
}

// forge test --fork-url https://base-mainnet.g.alchemy.com/v2/TJE11PfqHQaUQaRpRlkKfzwt8njReT2D --match-path ./test/Bond.t.sol  -vvv

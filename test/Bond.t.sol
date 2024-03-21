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
import { Tn100xBondIssuer } from "../src/Bond.sol";
import { BondProxy } from "../src/BondProxy.sol";

// Fork testing mainnet required
contract OvenTest is Test {
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
      abi.encodeWithSelector(Tn100xBondIssuer.initialize.selector, tn, _pool, weth)
    );
    bondIssuer = Tn100xBondIssuer(address(bondProxy));
    TN100x(tn).transfer(address(bondIssuer), 7_000_000 ether);
  }

  function testQuote() public {
    // uint256[] memory quote = pool.sample(weth, 1e18, 1, 1);
    bondIssuer.buy{value: 0.25 ether}();
    bondIssuer.bonds(1);
  }


}

// forge test --fork-url https://base-mainnet.g.alchemy.com/v2/TJE11PfqHQaUQaRpRlkKfzwt8njReT2D --match-path ./test/Bond.t.sol  -vvv

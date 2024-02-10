// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "ERC721A/extensions/ERC721AQueryable.sol";
import "solmate/utils/SSTORE2.sol";
import "solmate/auth/Owned.sol";
import "solmate/utils/LibString.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "solmate/tokens/ERC20.sol";
import "openzeppelin-contracts/utils/Address.sol";
import "prb-math/PRBMathUD60x18.sol";
import "./Base64.sol";
import "./TheLPRenderer.sol";

// 10 Billion total supply
// 40% LP
// 25% Burn to mint
// 25% Airdrop
// 5% ecosystem
// 2.5% vested two years

contract TheLP_ERC20_OLD is ERC20 {

    address public lpNftAddress;
    uint constant MAX_SUPPLY = 10_000_000_000 ether;
    uint amountPerBurn = 250_000 ether;

    error NotLp();
    error LpAddrNotSet();

    constructor(address _lpNftAddress) ERC20("LP", "LP", 18) {
        lpNftAddress = _lpNftAddress;
        uint totalMintedForBurn = amountPerBurn * 10_000;
        _mint(address(this), totalMintedForBurn);
        _mint(msg.sender, MAX_SUPPLY - totalMintedForBurn);
    }

    function mintForBurn(address to) public {
        if(lpNftAddress == address(0)) {
            revert LpAddrNotSet();
        }
        if(msg.sender != lpNftAddress) {
            revert NotLp();
        }
        transfer(to, amountPerBurn);
    }
}
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

contract TN100x is ERC20 {
    uint constant MAX_SUPPLY = 10_000_000_000 ether;
    constructor() ERC20("The Next 100x Memecoin on Base", "TN100x", 18) {
        _mint(msg.sender, MAX_SUPPLY);
    }
}
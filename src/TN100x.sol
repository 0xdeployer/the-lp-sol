pragma solidity ^0.8.17;
import "solmate/tokens/ERC20.sol";

contract TN100x is ERC20 {
    uint constant MAX_SUPPLY = 10_000_000_000 ether;
    constructor() ERC20("The Next 100x Memecoin on Base", "TN100x", 18) {
        _mint(msg.sender, MAX_SUPPLY);
    }
}
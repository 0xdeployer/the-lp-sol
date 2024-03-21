// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;


import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC721A } from "ERC721A/interfaces/IERC721A.sol";
import { ud } from "@prb/math/UD60x18.sol";

contract Tn100xBondIssuer is Owned, Initializable {
  uint256 private locked;
  address public tn100x;
  mapping(bytes => Floaty) public floatyHashToFloaty;
  mapping(address => mapping(bytes => uint256)) balanceOf;
  mapping(address => bool) signers;

  modifier nonReentrant() virtual {
    require(locked == 1, "REENTRANCY");

    locked = 2;

    _;

    locked = 1;
  }

  constructor() Owned(address(0)) {
    _disableInitializers();
  }

  function initialize(
    address _tn100x
  ) public initializer {
    locked = 1;
    tn100x = _tn100x;
    owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  function withdrawErc20(address token, address to) public onlyOwner {
    ERC20(token).transfer(to, ERC20(token).balanceOf(address(this)));
  }

  function withdrawEth(address to, uint amount) public payable onlyOwner {
     (bool sent, bytes memory data) = to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
  }

  function buyBond() public payable nonReentrant {

  }

   function _startTokenId() internal view override returns (uint256) {
    return 1;
  }
}

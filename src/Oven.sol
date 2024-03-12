// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC721A } from "ERC721A/interfaces/IERC721A.sol";
import { ud } from "@prb/math/UD60x18.sol";

contract Oven is Owned, Initializable {
  address public tn100x;
  address public lp;
  address public burnAddress;
  uint256 private locked;
  uint public start;

  modifier nonReentrant() virtual {
    require(locked == 1, "REENTRANCY");

    locked = 2;

    _;

    locked = 1;
  }

  error InvalidOwner();
  error HasNotStarted();

  constructor() Owned(address(0)) {
    _disableInitializers();
  }

  function initialize(address _tn100x, address _lp, uint _start) public initializer {
    lp = _lp;
    tn100x = _tn100x;
    locked = 1;
    owner = msg.sender;
    start = _start;
    burnAddress = 0x000000000000000000000000000000000000dEaD;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  /// @dev This function returns the amount of TN100x that can be
  /// redeemed by burning a Based LP NFT.
  function getBurnAmount(uint256 tokenId)
    public
    view
    returns (uint256 amountPerToken)
  {
    // verify token exists and is not owned by 0 address
    IERC721A lp721 = IERC721A(lp);
    ERC20 tnErc20 = ERC20(tn100x);
    address owner = lp721.ownerOf(tokenId);
    if (owner == burnAddress) {
      revert InvalidOwner();
    }
    // get total number of tokens owned by burn address
    uint256 totalBurnt = lp721.balanceOf(burnAddress);
    uint256 totalMinted = lp721.totalSupply();
    uint256 tn100xBalance = tnErc20.balanceOf(address(this));

    uint256 total = totalMinted - totalBurnt;

    amountPerToken = ud(tn100xBalance)
      .div(ud(total * 10**18))
      .mul(ud(0.6 * 10**18))
      .intoUint256();
  }

  function _burnAndRedeem(uint256 tokenId) private {
    uint256 amountToRedeem = getBurnAmount(tokenId);
    IERC721A(lp).transferFrom(msg.sender, burnAddress, tokenId);
    ERC20(tn100x).transfer(msg.sender, amountToRedeem);
  }

  function hasStarted() public view returns(bool){
    return block.timestamp >= start;
  }

  function burnAndRedeem(uint256[] memory tokenIds) public nonReentrant {
    if(!hasStarted()) {
      revert HasNotStarted();
    }
    for (uint256 i = 0; i < tokenIds.length; ) {
      _burnAndRedeem(tokenIds[i]);
      unchecked {
        ++i;
      }
    }
  }

  function withdrawErc20(address token, address to) public onlyOwner {
    ERC20(token).transfer(to, ERC20(token).balanceOf(address(this)));
  }
}

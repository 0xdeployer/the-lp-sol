// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC721A } from "ERC721A/interfaces/IERC721A.sol";
import { ud } from "@prb/math/UD60x18.sol";
import { Tn100xBondNft } from "./BondNft.sol";
import { IPool } from "aerodrome/interfaces/IPool.sol";

contract Tn100xBondIssuer is Owned, Initializable {
  uint256 private locked;
  address public tn100x;
  // 0x4200000000000000000000000000000000000006
  address public weth;
  //0x8f5F1D63599362115e7F9fe71BFD5ab883D82c82
  address public pool;
  uint256 public basisPoints;
  uint256 public timeToMaturity;
  Tn100xBondNft public bondNft;

  mapping(uint256 => Bond) public bonds;
  struct Bond {
    uint256 maturesAt;
    uint256 tokenAmount;
    bool deleted;
    bool exists;
  }

  error NotOwnerOfBond();
  error NotMature();
  error InvalidBond();

  event Redeem(uint256 tokenId, uint256 amount, address to);
  event Buy(
    uint256 tokenId,
    uint256 bondAmount,
    uint256 maturesAt,
    address owner
  );

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
    address _tn100x,
    address _pool,
    address _weth
  ) public initializer {
    locked = 1;
    tn100x = _tn100x;
    weth = _weth;
    pool = _pool;
    owner = msg.sender;
    timeToMaturity = 3 days;
    basisPoints = 1000;
    bondNft = new Tn100xBondNft();
    emit OwnershipTransferred(address(0), msg.sender);
  }

  function updateBasisPoints(uint256 points) public onlyOwner {
    basisPoints = points;
  }

  function updateTimeToMaturity(uint256 time) public onlyOwner {
    timeToMaturity = time;
  }

  function withdrawErc20(address token, address to) public onlyOwner {
    ERC20(token).transfer(to, ERC20(token).balanceOf(address(this)));
  }

  function withdrawEth(address to, uint256 amount) public payable onlyOwner {
    (bool sent, bytes memory data) = to.call{ value: msg.value }("");
    require(sent, "Failed to send Ether");
  }

  function getPrice(uint256 value) public view returns (uint256) {
    uint256 amountOut = IPool(pool).getAmountOut(value, weth);
    uint256 bonus = (amountOut * basisPoints) / 10000;
    return amountOut + bonus;
  }

  function redeem(uint256 tokenId) public nonReentrant {
    if (msg.sender != bondNft.ownerOf(tokenId)) {
      revert NotOwnerOfBond();
    }
    if (!bonds[tokenId].exists || bonds[tokenId].deleted) {
      revert InvalidBond();
    }
    if (block.timestamp < bonds[tokenId].maturesAt) {
      revert NotMature();
    }
    bondNft.burn(tokenId);
    ERC20(tn100x).transfer(msg.sender, bonds[tokenId].tokenAmount);
    bonds[tokenId].deleted = true;
    emit Redeem(tokenId, bonds[tokenId].tokenAmount, msg.sender);
  }

  function buy() public payable nonReentrant {
    // get amount out
    uint256 price = getPrice(msg.value);
    uint256 nextTokenId = bondNft.nextTokenId();
    bondNft.mint(msg.sender);
    bonds[nextTokenId] = Bond({
      maturesAt: block.timestamp + timeToMaturity,
      tokenAmount: price,
      deleted: false,
      exists: true
    });
    emit Buy(nextTokenId, price, bonds[nextTokenId].maturesAt, msg.sender);
  }
}

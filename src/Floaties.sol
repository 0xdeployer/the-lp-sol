// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC721A } from "ERC721A/interfaces/IERC721A.sol";
import { ud } from "@prb/math/UD60x18.sol";

contract Floaties is Owned, Initializable {
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

  struct Floaty {
    bytes floatyHash;
    address tokenAddress;
    uint256 tokenPerFloaty;
  }

  error InvalidFloaty();
  error InvalidAmount();
  error InvalidSigner();

event InitFloaty(bytes floatyHash, address tokenAddress, uint tokenPerFloaty);
  event SignerUpdate(address signer, bool value);

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

  function modifySigner(address signer, bool value) public onlyOwner {
    signers[signer] = value;
    emit SignerUpdate(signer, value);
  }

  function withdrawErc20(address token, address to) public onlyOwner {
    ERC20(token).transfer(to, ERC20(token).balanceOf(address(this)));
  }

  function initFloaty(
    bytes memory floatyHash,
    address tokenAddress,
    uint256 tokenPerFloaty
  ) public onlyOwner {
    floatyHashToFloaty[floatyHash] = Floaty({
        floatyHash: floatyHash,
        tokenAddress: tokenAddress,
        tokenPerFloaty: tokenPerFloaty
    });
    emit InitFloaty(floatyHash, tokenAddress, tokenPerFloaty);
  }

  function spend(
    address to,
    address from,
    bytes memory floatyHash,
    uint256 floatyAmount
  ) public {
    if (signers[msg.sender] == false) {
      revert InvalidSigner();
    }
  }

  function buyWithApproval(
    bytes memory floatyHash,
    uint256 floatyAmount,
    uint256 tokenAmount,
    uint256 tnFee,
    uint256 tnDeadline,
    uint8 tnV,
    bytes32 tnR,
    bytes32 tnS
  ) public {}

  function buyWithPermit(
    bytes memory floatyHash,
    uint256 floatyAmount,
    uint256 totalCost,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint256 tnFee,
    uint256 tnDeadline,
    uint8 tnV,
    bytes32 tnR,
    bytes32 tnS
  ) public {
    Floaty memory floaty = floatyHashToFloaty[floatyHash];
    if (floaty.tokenAddress == address(0)) {
      revert InvalidFloaty();
    }
    uint256 verifiedCost = floatyAmount * floaty.tokenPerFloaty;
    if (totalCost != verifiedCost) {
      revert InvalidAmount();
    }

    // calculate fee
    // send fee somewhere

    // transfer token to this contract
    ERC20(floaty.tokenAddress).permit(
      msg.sender,
      address(this),
      totalCost,
      deadline,
      v,
      r,
      s
    );
    ERC20(floaty.tokenAddress).transferFrom(
      msg.sender,
      address(this),
      totalCost
    );

    balanceOf[msg.sender][floatyHash] += floatyAmount;
  }
}
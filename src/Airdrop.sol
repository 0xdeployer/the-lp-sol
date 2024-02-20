// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

contract Airdropper is Owned {
  bytes32 public merkleRoot;
  address public tn100x;
  mapping(address => bool) public hasClaimed;

  error InvalidProof();
  error HasClaimed();

  constructor(bytes32 _root, address _tn100x) Owned(msg.sender) {
    merkleRoot = _root;
    tn100x = _tn100x;
  }

  function _claim(uint256 amount, bytes32[] calldata proof) internal {
    bytes32 leaf = keccak256(abi.encode(msg.sender, amount));
    if (!MerkleProofLib.verify(proof, merkleRoot, leaf)) {
      revert InvalidProof();
    }
    if (hasClaimed[msg.sender]) {
      revert HasClaimed();
    }
    hasClaimed[msg.sender] = true;
  }

  function claim(uint256 amount, bytes32[] calldata proof) public {
    _claim(amount, proof);
    ERC20(tn100x).transfer(msg.sender, amount);
  }

  function withdraw(address to) public onlyOwner {
    ERC20(tn100x).transfer(to, ERC20(tn100x).balanceOf(address(this)));
  }
}

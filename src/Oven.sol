// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ud } from "@prb/math/UD60x18.sol";

contract Oven is Owned, Initializable {
    address public tn100x;
    address public lp; 

    constructor() Owned(address(0)) {
        _disableInitializers();
    }

    function initialize(address _tn100x)
        public
        initializer
    {
        tn100x = _tn100x;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function getBurnAmounts(uint tokenId) returns(uint[2] memory out) {
        // verify token exists and is not owned by 0 address
        address owner = IERC721(lp).ownerOf(tokenId);
    } 

}
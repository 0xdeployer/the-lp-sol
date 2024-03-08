// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC721A } from "ERC721A/interfaces/IERC721A.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";
import { ud } from "@prb/math/UD60x18.sol";

contract Oven is Owned, Initializable, ReentrancyGuard {
    address public tn100x;
    address public lp; 
    address public burnAddress;

    error InvalidOwner();

    constructor() Owned(address(0)) {
        _disableInitializers();
    }

    function initialize(address _tn100x, address _lp)
        public
        initializer
    {
        lp = _lp;
        tn100x = _tn100x;
        owner = msg.sender;
        burnAddress = 0x000000000000000000000000000000000000dEaD;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @dev This function returns the amount of TN100x that can be 
    /// redeemed by burning a Based LP NFT.
    function getBurnAmount(uint tokenId) public view returns(uint amountPerToken) {
        // verify token exists and is not owned by 0 address
        IERC721A lp721 = IERC721A(lp);
        ERC20 tnErc20 = ERC20(tn100x);
        address owner = lp721.ownerOf(tokenId);
        if(owner == burnAddress) {
            revert InvalidOwner();
        }
        // get total number of tokens owned by burn address
        uint totalBurnt = lp721.balanceOf(burnAddress);
        uint totalMinted = lp721.totalSupply();
        uint tn100xBalance = tnErc20.balanceOf(address(this));

        uint total = totalMinted - totalBurnt;

        amountPerToken = ud(tn100xBalance).div(ud(total * 10**18)).mul(ud(0.6 * 10 ** 18)).intoUint256();
    }

    function _burnAndRedeem(uint tokenId) private {
        uint amountToRedeem = getBurnAmount(tokenId);
        IERC721A(lp).transferFrom(msg.sender, burnAddress, tokenId);
        ERC20(tn100x).transfer(msg.sender, amountToRedeem);
    }

    function burnAndRedeem(uint[] memory tokenIds) public nonReentrant {
        for(uint i = 0; i < tokenIds.length;) {
            _burnAndRedeem(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { ERC721A, ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import { IERC721A } from "ERC721A/interfaces/IERC721A.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { Base64 } from "./Base64.sol";
import { SSTORE2 } from "solmate/utils/SSTORE2.sol";
import { LibString } from "solmate/utils/LibString.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";

contract GoldenHam is ERC721AQueryable, Owned, ReentrancyGuard {
  address imagePointer;
  uint256 public mintEndDate;
  uint256 public lockingPeriodEndDate;
  address public tn100x;
  mapping(uint256 => uint256) public tokenIdToAmountLocked;
  uint256 public totalLocked;

  error InvalidAmount();
  error MintEnded();
  error TokenDoesNotExist();
  error NotOwner();
  error NothingLockedForToken();
  error LockingPeriodNotEnded();

  constructor(
    string memory _image,
    uint256 _mintEndDate,
    uint256 _lockingPeriodEnd,
    address _tn100x
  ) ERC721A("Golden Ham", "GH") Owned(msg.sender) {
    imagePointer = SSTORE2.write(bytes(_image));
    mintEndDate = _mintEndDate;
    lockingPeriodEndDate = _lockingPeriodEnd;
    tn100x = _tn100x;
  }

  function updateMintEndDate(uint256 _mintEndDate) public onlyOwner {
    mintEndDate = _mintEndDate;
  }

  function updateLockingPeriodEndDate(uint256 _lockingPeriodEndDate)
    public
    onlyOwner
  {
    lockingPeriodEndDate = _lockingPeriodEndDate;
  }

  function _startTokenId() internal view override returns (uint256) {
    return 1;
  }

  function _withdraw(uint256 tokenId) private {
    if (tokenIdToAmountLocked[tokenId] == 0) {
      revert NothingLockedForToken();
    }
    if (ownerOf(tokenId) != msg.sender) {
      revert NotOwner();
    }
    uint256 amount = tokenIdToAmountLocked[tokenId];
    tokenIdToAmountLocked[tokenId] = 0;
    ERC20(tn100x).transfer(msg.sender, amount);
  }

  function withdraw(uint256[] memory tokenIds) public nonReentrant {
    if(block.timestamp < lockingPeriodEndDate) {
      revert LockingPeriodNotEnded();
    }
    for (uint256 i = 0; i < tokenIds.length; ) {
      _withdraw(tokenIds[i]);
      unchecked {
        i++;
      }
    }
  }

  function mint(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
    if (block.timestamp > mintEndDate) {
      revert MintEnded();
    }
    if (amount <= 0) {
      revert InvalidAmount();
    }

    ERC20(tn100x).permit(msg.sender, address(this), amount, deadline, v, r, s);
    ERC20(tn100x).transferFrom(msg.sender, address(this), amount);

    tokenIdToAmountLocked[_nextTokenId()] = amount;
    totalLocked += amount;
    _mint(msg.sender, 1);
  }

  function _getSvgString(string memory dataUri)
    private
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40" height="350" width="350"><image width="40" height="40" image-rendering="pixelated" href="',
          dataUri,
          '" /></svg>'
        )
      );
  }

  function _getTraitString(string memory key, string memory value)
    private
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked('{"trait_type":"', key, '","value":"', value, '"}')
      );
  }

  function _getTraitString(string memory key, uint256 value)
    private
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"',
          key,
          '","value":"',
          LibString.toString(value),
          '"}'
        )
      );
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A, IERC721A)
    returns (string memory)
  {
    if (!_exists(tokenId)) {
      revert TokenDoesNotExist();
    }
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            (
              abi.encodePacked(
                '{"name": "',
                "The Golden Ham",
                '", "description": "',
                "A golden ham is filled with $TN100x",
                '",',
                '"image":"',
                string(
                  abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                      bytes(_getSvgString(string(SSTORE2.read(imagePointer))))
                    )
                  )
                ),
                '","attributes":[',
                _getTraitString("$TN100x", tokenIdToAmountLocked[tokenId]),
                "]}"
              )
            )
          )
        )
      );
  }
}

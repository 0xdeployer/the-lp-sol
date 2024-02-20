// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "solmate/utils/SSTORE2.sol";
import "solmate/utils/LibString.sol";
import "./Base64.sol";

contract Items is ERC721Enumerable, Ownable2Step {
  using EnumerableSet for EnumerableSet.AddressSet;
  using LibString for uint256;

  EnumerableSet.AddressSet approvedSigners;

  struct Item {
    string name;
    string image;
    string description;
    uint256[] numberAttributeValues;
    string[] stringAttributeValues;
    string[] numberAttributeKeys;
    string[] stringAttributeKeys;
    uint maxSupply;
    uint totalSupply;
    bool exists;
    bool locked;
  }

  mapping(uint256 => Item) public items;
  uint256 totalItems;

  constructor() ERC721("Items", "items") {}

  function addSigner(address signer) public onlyOwner {
    approvedSigners.add(signer);
  }

  function removeSigner(address signer) public onlyOwner {
    approvedSigners.remove(signer);
  }

  function containsSigner(address signer) public view returns (bool) {
    return approvedSigners.contains(signer);
  }

  function initItem(
    string memory name,
    string memory description,
    string memory image,
    uint maxSupply,
    uint256[] memory numberAttributeValues,
    string[] memory stringAttributeValues,
    string[] memory numberAttributeKeys,
    string[] memory stringAttributeKeys
  ) public onlyOwner {
    unchecked {
      ++totalItems;
    }
    items[totalItems] = Item(
      name,
      image,
      description,
      numberAttributeValues,
      stringAttributeValues,
      numberAttributeKeys,
      stringAttributeKeys,
      maxSupply,
      0,
      true,
      false
    );
  }

  modifier onlySignerOrOwner() {
    require(
      owner() == _msgSender() || containsSigner(_msgSender()),
      "Ownable: caller is not the owner"
    );
    _;
  }

  error Locked();

  modifier notLocked(uint id) {
    if (items[id].locked) {
      revert Locked();
    }
    _;
  }

  uint currentTokenId;
  mapping(uint => uint) public tokenIdToItemId;
  error ItemDoesNotExist();
  error ItemMaxSupplyReached();

  function mint(uint itemId, address to) public onlySignerOrOwner {
    if (!items[itemId].exists) {
      revert ItemDoesNotExist();
    }
    if(items[itemId].totalSupply == items[itemId].maxSupply) {
      revert ItemMaxSupplyReached();
    }
    unchecked {
      ++currentTokenId;
    }
    tokenIdToItemId[currentTokenId] = itemId;
    items[itemId].totalSupply += 1;
    _mint(to, currentTokenId);
  }

  error TokenDoesNotExist();

  function _getTraitString(
    string memory key,
    string memory value
  ) private pure returns (string memory) {
    return
      string(
        abi.encodePacked('{"trait_type":"', key, '","value":"', value, '"}')
      );
  }

  function _getTraitString(
    string memory key,
    uint value
  ) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{"trait_type":"',
          key,
          '","value":"',
          value.toString(),
          '"}'
        )
      );
  }

  function _getTraitMetadata(uint itemId) private view returns (string memory) {
    string memory out;
    // handle number attrs
    // hand string attrs
    for (uint i = 0; i < items[itemId].stringAttributeKeys.length; i++) {
      out = string(
        abi.encodePacked(
          out,
          bytes(out).length > 0 ? "," : "",
          _getTraitString(
            items[itemId].stringAttributeKeys[i],
            items[itemId].stringAttributeValues[i]
          )
        )
      );
    }
    for (uint i = 0; i < items[itemId].numberAttributeKeys.length; i++) {
      out = string(
        abi.encodePacked(
          out,
          bytes(out).length > 0 ? "," : "",
          _getTraitString(
            items[itemId].numberAttributeKeys[i],
            items[itemId].numberAttributeValues[i]
          )
        )
      );
    }
    return out;
  }

  function tokenURI(uint tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) {
      revert TokenDoesNotExist();
    }
    uint itemId = tokenIdToItemId[tokenId];
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            (
              abi.encodePacked(
                '{"name": "',
                items[itemId].name,
                '", "description": "',
                items[itemId].description,
                '",',
                '"image":"',
                items[itemId].image,
                '","attributes":[',
                _getTraitMetadata(itemId),
                "]}"
              )
            )
          )
        )
      );
  }

  function updateMaxSupply(uint id, uint supply) external onlyOwner notLocked(id) {
    items[id].maxSupply = supply;
  }

  function updateItemImage(
    uint id,
    string calldata image
  ) external onlyOwner notLocked(id) {
    items[id].image = image;
  }

  function getItemImage(uint id) public view returns (string memory) {
    return items[id].image;
  }

  function updateItemAttributeValues(
    uint256 id,
    uint256[] memory attributeValues
  ) public onlyOwner notLocked(id) {
    items[id].numberAttributeValues = attributeValues;
  }

  function updateItemAttributeValues(
    uint256 id,
    string[] memory attributeValues
  ) public onlyOwner notLocked(id) {
    items[id].stringAttributeValues = attributeValues;
  }

  function updateItemAttributeStringKeys(
    uint256 id,
    string[] memory keys
  ) public onlyOwner notLocked(id) {
    items[id].stringAttributeKeys = keys;
  }

  function updateItemAttributeNumberKeys(
    uint256 id,
    string[] memory keys
  ) public onlyOwner notLocked(id) {
    items[id].numberAttributeKeys = keys;
  }

  function updateItemName(
    uint256 id,
    string memory name
  ) public onlyOwner notLocked(id) {
    items[id].name = name;
  }

  function updateItemDescription(
    uint256 id,
    string memory description
  ) public onlyOwner notLocked(id) {
    items[id].description = description;
  }

  error ItemAlreadyLocked();

  function lockItem(uint256 id) public onlyOwner notLocked(id) {
    items[id].locked = true;
  }
}

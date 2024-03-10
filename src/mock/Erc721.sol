pragma solidity ^0.8.17;
import { ERC721A, ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";

contract Test721 is ERC721AQueryable {
  constructor() ERC721A("TEST", "TEST") {
    _mint(msg.sender, 3331);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}

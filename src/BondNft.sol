import { ERC721A, ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import { Owned } from "solmate/auth/Owned.sol";

contract Tn100xBondNft is ERC721AQueryable, Owned {

    constructor() ERC721A("TN100x Bond NFT", "TN100xBond") Owned(msg.sender) {}

    function mint(address to) external onlyOwner {
        _mint(to, 1);
    }

    function burn(uint tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function nextTokenId() view external returns (uint) {
        return _nextTokenId();
    }     
    
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}
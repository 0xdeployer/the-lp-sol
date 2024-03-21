import { ERC721A, ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import { Owned } from "solmate/auth/Owned.sol";

contract Tn100xBondNft is ERC721AQueryable, Owned {

    constructor() ERC721A("TN100x Bond NFT", "TN100xBond") Owned(msg.sender) {}

    function mint(address to) public onlyOwner {
        _mint(to, 1);
    }
}
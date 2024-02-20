// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { ERC721A, ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import { IERC721A } from "ERC721A/interfaces/IERC721A.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ICurve } from "lssvm2/bonding-curves/ICurve.sol";
import { LSSVMPair } from "lssvm2/LSSVMPair.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";
import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { TheLPRenderer } from "./TheLPRenderer.sol";
import { IPairFactoryLike } from "./IPairFactoryLike.sol";

contract TheLP is ERC721AQueryable, Owned, ReentrancyGuard {
  TheLPRenderer renderer;

  event PaymentReceived(address from, uint256 amount);
  event PaymentReleased(address to, uint256 amount);
  event Refund(address to, uint256 amount);

  uint256 public MAX_SUPPLY;
  uint256 public MAX_PUB_SALE = 2900
  uint256 public MAX_TEAM = 333;
  uint256 public MAX_LP = 100;
  uint256 public DURATION;
  uint256 public MIN_PRICE = 0.001 ether;
  uint256 public MAX_PRICE = 1 ether;
  uint256 public DISCOUNT_RATE;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public finalCost;
  address public traitsImagePointer;
  uint256 public totalEthClaimed;
  bool public poolInitialized;
  bool public lockedIn = false;
  uint256 public feeSplit = 2 * 10**18;
  address public erc20Address;
  mapping(uint256 => uint256) public _rewardDebt;
  mapping(uint256 => TokenMintInfo) public tokenMintInfo;
  struct TokenMintInfo {
    bytes32 seed;
    uint256 cost;
  }

  address private immutable SUDO_FACTORY;
  address private immutable LINEAR_ADDRESS;

  error TokenNotForSale();
  error IncorrectPayment();
  error AlreadyLocked();
  error NotGameOver();
  error AlreadyGameOver();
  error LockedIn();
  error CannotRedeem();
  error InvalidTokenId(uint256 tokenId);
  error NotOwner(uint256 tokenId);
  error AuctionEnded();
  error NotStarted();
  error AmountRequired();
  error SoldOut();
  error NotLockedIn();
  error PoolInitialized();
  error AmountExceedsAvailableSupply();

  bytes32 teamMintBlockHash;
  bytes32 lpMintBlockHash;
  address teamMintWallet;

  constructor(
    string memory name,
    string memory symbol,
    uint256 _startTime,
    TheLPRenderer _renderer,
    uint256 minPrice,
    uint256 maxPrice,
    uint256 maxPubSale,
    uint256 maxTeam,
    uint256 maxLp,
    uint256 duration,
    address _teamMintWallet,
    address _factory,
    address _linear
  ) ERC721A(name, symbol) Owned(msg.sender) {
    SUDO_FACTORY = _factory;
    LINEAR_ADDRESS = _linear;
    startTime = _startTime;
    endTime = startTime + duration;
    renderer = _renderer;
    MAX_SUPPLY = MAX_LP + MAX_TEAM + MAX_PUB_SALE;
    DURATION = duration;
    DISCOUNT_RATE = ud(MAX_PRICE - MIN_PRICE)
      .div(ud((duration) * 10**18))
      .intoUint256();
    teamMintWallet = _teamMintWallet;
    _mintERC2309(teamMintWallet, MAX_TEAM);
    teamMintBlockHash = blockhash(block.number - 1);
  }

  /// @dev Public function to get the usable ETH balanance.
  /// This balance does not include ETH set aside of holder fees.
  function getEthBalance() external view returns (uint256) {
    return _getEthBalance(0);
  }

  /// @dev Private function to get usable ETH balance of the smart contract.
  /// This ETH balance is what is used for liquidity. It should not include
  /// ETH that is set aside for fees. Includes minus argument to subtract
  /// msg.value which should not be included in calculation.
  function _getEthBalance(uint256 minus) private view returns (uint256) {
    uint256 balance = address(this).balance - minus;
    uint256 fees = getFeeBalance();
    if (fees > balance) return 0;
    return balance - fees;
  }

  /// @dev Public function to update the fee split
  function updateFeeSplit(uint256 newSplit) public onlyOwner {
    feeSplit = newSplit;
  }

  error ApprovalRequired(uint256 tokenId);

  uint256 private _totalFees;

  /// @dev Function to get the total fees accumulated over time
  function getFeeBalance() public view returns (uint256) {
    return _totalFees;
  }

  /// @dev Function to manually migrate ETH from pool
  /// Can be disabled by changing owner to address(0)
  function migrate(uint256 amount) public onlyOwner {
    Address.sendValue(payable(owner), amount);
  }

  /// @dev Public function that can be used to calculate the pending ETH payment for a given NFT ID
  function calculatePendingPayment(uint256 nftId)
    public
    view
    returns (uint256)
  {
    uint256 a = getFeeBalance() + totalEthClaimed - _rewardDebt[nftId];
    if (a == 0) return 0;
    return ud(a).div(ud(MAX_SUPPLY * 10**18)).intoUint256();
  }

  error InvalidDepositAmount();


  error NothingToClaim();

  /// @dev Internal function used to claim share of fees for a given NFT ID
  /// Throws if trying to claim for NFTs in pool
  function _claim(uint256 nftId) private {
    if (!lockedIn) {
      revert NotLockedIn();
    }
    uint256 payment = calculatePendingPayment(nftId);
    if (payment == 0) {
      revert NothingToClaim();
    }
    totalEthClaimed += payment;
    address ownerAddr = ownerOf(nftId);
    if (ownerAddr == address(this)) {
      revert NothingToClaim();
    }
    _totalFees -= payment;
    _rewardDebt[nftId] = _totalFees + totalEthClaimed;
    Address.sendValue(payable(ownerAddr), payment);
    emit PaymentReleased(ownerAddr, payment);
  }

  /// @dev Public function used to claim share of available fees for a given NFT ID
  function claim(uint256 nftId) public nonReentrant {
    _claim(nftId);
  }

  /// @dev Convenience method to claim fees for many NFT IDs
  function claimMany(uint256[] memory nftIds) public nonReentrant {
    for (uint256 i = 0; i < nftIds.length; i++) {
      _claim(nftIds[i]);
    }
  }

  /// @dev Get on-chain token URI
  /// Accounts for NFTs that were minted using ERC-2309
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A, IERC721A)
    returns (string memory)
  {
    bytes32 seed;
    // 1 - 1000
    if (tokenId <= MAX_TEAM) {
      seed = keccak256(abi.encodePacked(teamMintBlockHash, tokenId));
      // 9001 - 10000
    } else if (tokenId >= MAX_PUB_SALE + MAX_TEAM + 1) {
      seed = keccak256(abi.encodePacked(lpMintBlockHash, tokenId));
    } else {
      // 1001 - 9000
      seed = tokenMintInfo[tokenId].seed;
    }
    return renderer.getJsonUri(tokenId, seed);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /// @dev Public function that returns game over status
  function isGameOver() public view returns (bool) {
    return block.timestamp >= endTime && _totalMinted() < MAX_SUPPLY;
  }

  /// @dev Private function to redeem mint costs for a given NFT ID
  function _redeem(uint256 tokenId) private {
    if (tokenMintInfo[tokenId].cost == 0) {
      revert InvalidTokenId(tokenId);
    }
    if (ownerOf(tokenId) != msg.sender) {
      revert NotOwner(tokenId);
    }
    uint256 amount = tokenMintInfo[tokenId].cost;
    Address.sendValue(payable(msg.sender), amount);
    tokenMintInfo[tokenId].cost = 0;
    emit Refund(msg.sender, amount);
  }

  /// @dev Public function to redeem mint costs for multiple NFT IDs
  /// This function can only be called if game over is true.
  function redeem(uint256[] memory tokenIds) public nonReentrant {
    if (!isGameOver()) {
      revert NotGameOver();
    }

    for (uint256 i = 0; i < tokenIds.length; i++) {
      _redeem(tokenIds[i]);
    }
  }

  function _claimRefund(uint256 tokenId) private {
    if (tokenMintInfo[tokenId].cost == 0) {
      revert InvalidTokenId(tokenId);
    }
    if (ownerOf(tokenId) != msg.sender) {
      revert NotOwner(tokenId);
    }
    if (tokenMintInfo[tokenId].cost > finalCost) {
      uint256 amount = tokenMintInfo[tokenId].cost - finalCost;
      Address.sendValue(payable(msg.sender), amount);
      emit Refund(msg.sender, amount);
    }
    tokenMintInfo[tokenId].cost = 0;
  }

  function claimRefund(uint256[] memory tokenIds) public nonReentrant {
    if (!lockedIn) {
      revert NotLockedIn();
    }
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _claimRefund(tokenIds[i]);
    }
  }

  /// @dev This function disables transfers until mint is complete.
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override {
    if (from == address(0)) return;
    if (!lockedIn) {
      revert NotLockedIn();
    }
  }

  uint poolEthAmount;

  /// @dev Private function that is called once the last NFT of public sale is minted.
  function _lockItIn() private {
    if (lockedIn) {
      revert AlreadyLocked();
    }
    lockedIn = true;
    // Get available funds minus refunds
    uint256 totalAvailableEth = (_totalMinted() - MAX_TEAM) * finalCost;
    // To be used in Uniswap pool

    // whats the final price and how much eth is required to put in the pool
    // for 100 to equal that price?
    poolEthAmount = finalCost * 100;

    Address.sendValue(
      payable(owner),
      totalAvailableEth - poolEthAmount
    );
    lpMintBlockHash = blockhash(block.number - 1);
  }

  /// @dev Initializing pool on SudoSwap
  function _initSudoPool() internal returns (address tradePool) {
    poolInitialized = true;
    uint256[] memory empty = new uint256[](0);
    tradePool = address(
      IPairFactoryLike(SUDO_FACTORY).createPairERC721ETH(
        IERC721(address(this)),
        ICurve(LINEAR_ADDRESS),
        payable(address(this)),
        LSSVMPair.PoolType.TRADE,
        uint128(finalCost),
        0,
        uint128(finalCost),
        address(0),
        empty
      )
    );
    _mint(tradePool, 100);
    (bool sent, bytes memory data) = tradePool.call{value: poolEthAmount }("");
    require(sent, "Failed to send Ether");
  }

  function initSudoPool() public nonReentrant {
    if(poolInitialized) {
        revert PoolInitialized();
    }
    if(!lockedIn) {
        revert NotLockedIn();
    }
    _initSudoPool();
  }

  /// @dev Gets the current mint price for dutch auction
  function getCurrentMintPrice() public view returns (uint256) {
    if (block.timestamp < startTime) {
      revert NotStarted();
    }
    uint256 timeElapsed = block.timestamp - startTime;
    uint256 discount = DISCOUNT_RATE * timeElapsed;
    if (discount > MAX_PRICE) return MIN_PRICE;
    return MAX_PRICE - discount;
  }

  /// @dev Public mint function
  /// Must pass msg.value greater than or equal to current mint price * amount
  function mint(uint256 amount) public payable nonReentrant {
    if(lockedIn) {
        revert SoldOut();
    }
    if (block.timestamp >= endTime) {
      revert AuctionEnded();
    }
    if (block.timestamp < startTime) {
      revert NotStarted();
    }
    if (amount <= 0) {
      revert AmountRequired();
    }
    uint256 totalAfterMint = _totalMinted() + amount;
    if (totalAfterMint > MAX_PUB_SALE + MAX_TEAM) {
      revert AmountExceedsAvailableSupply();
    }
    uint256 mintPrice = getCurrentMintPrice();
    uint256 totalCost = amount * mintPrice;
    if (msg.value < totalCost) {
      revert IncorrectPayment();
    }
    uint256 current = _nextTokenId();
    uint256 end = current + amount - 1;

    for (; current <= end; current++) {
      tokenMintInfo[current] = TokenMintInfo({
        seed: keccak256(abi.encodePacked(blockhash(block.number - 1), current)),
        cost: mintPrice
      });
    }
    uint256 refund = msg.value - totalCost;
    if (refund > 0) {
      Address.sendValue(payable(msg.sender), refund);
    }
    _mint(msg.sender, amount);
    if (totalAfterMint == MAX_PUB_SALE + MAX_TEAM) {
      finalCost = mintPrice;
      _lockItIn();
    }
  }

  /// @dev Receive function called when this contract receives Ether
  receive() external payable virtual {
    emit PaymentReceived(msg.sender, msg.value);
  }
}

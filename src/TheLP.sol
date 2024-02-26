// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { ERC721A, ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import { ERC2981 } from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import { IERC721A } from "ERC721A/interfaces/IERC721A.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ICurve } from "lssvm2/bonding-curves/ICurve.sol";
import { LSSVMPair } from "lssvm2/LSSVMPair.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";
import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { ud } from "@prb/math/UD60x18.sol";
import { TheLPRenderer } from "./TheLPRenderer.sol";
import { IPairFactoryLike } from "./IPairFactoryLike.sol";
import { IPairHooks } from "./IPairHooks.sol";

contract TheLP is
  ERC721AQueryable,
  Owned,
  ReentrancyGuard,
  IPairHooks,
  ERC2981
{
  TheLPRenderer renderer;

  event PaymentReceived(address from, uint256 amount);
  event PaymentReleased(address to, uint256 amount);
  event Refund(address to, uint256 amount);

  uint256 public MAX_SUPPLY;
  uint256 public MAX_PUB_SALE = 2900;
  uint256 public MAX_TEAM = 333;
  uint256 public MAX_LP = 100;
  uint256 public DURATION;
  uint256 public MIN_PRICE = 0.001 ether;
  uint256 public MAX_PRICE = 0.1 ether;
  uint256 public DISCOUNT_RATE;
  uint256 public startTime;
  address public tradePool;
  uint256 public endTime;
  uint256 public finalCost;
  address public traitsImagePointer;
  uint256 public totalEthClaimed;
  uint256 public royalty = 500;
  bool public poolInitialized;
  bool public lockedIn = false;
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
  error SenderNotPair();
  error InvalidDepositAmount();
  error NothingToClaim();

  bytes32 teamMintBlockHash;
  bytes32 lpMintBlockHash;
  address teamMintWallet;

  constructor(
    string memory name,
    string memory symbol,
    uint256 _startTime,
    TheLPRenderer _renderer,
    uint256 duration,
    address _factory,
    address _linear,
    address tn100x
  ) ERC721A(name, symbol) Owned(msg.sender) {
    erc20Address = tn100x;
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
    teamMintWallet = msg.sender;
    _mintERC2309(teamMintWallet, MAX_TEAM);
    teamMintBlockHash = blockhash(block.number - 1);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC721A, ERC721A, ERC2981)
    returns (bool)
  {
    return
      super.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }

  function withdrawErc20(address token, address to) public onlyOwner {
    ERC20(token).transfer(to, ERC20(token).balanceOf(address(this)));
  }

  function getRedeemAmount() public view returns(uint){
    return ud(ERC20(erc20Address).balanceOf(address(this)))
      .div(ud(totalSupply() * 10 ** 18))
      .intoUint256();
    
  }

  function _burnAndRedeem(uint nftId) private {
    if(ownerOf(nftId) != msg.sender) {
      revert NotOwner(nftId);
    }
    uint amount = getRedeemAmount();
    ERC20(erc20Address).transfer(msg.sender, amount);
    _burn(nftId);
  }

  function burnAndRedeem(uint[] memory nftIds) public nonReentrant {
    // Should not be able to redeem until locked in and trade pool created.
    if(!lockedIn || tradePool == address(0)) {
      revert NotLockedIn();
    }
    for(uint i = 0; i< nftIds.length; i++) {
      _burnAndRedeem(nftIds[i]);
    }
  }

  function updateRoyalty(uint256 _royalty) public onlyOwner {
    royalty = _royalty;
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    public
    view
    override
    returns (address, uint256)
  {
    uint256 royaltyAmount = (_salePrice * royalty) / _feeDenominator();
    return (address(this), royaltyAmount);
  }

  function _onlyPair() internal {
    if (tradePool == address(0)) return;
    if (msg.sender != tradePool) {
      revert SenderNotPair();
    }
  }

  function afterNewPair() external {
    _onlyPair();
  }

  // Also need to factor in new token balance and new NFT balance during calculations
  function afterSwapNFTInPair(
    uint256 _tokensOut,
    uint256 _tokensOutProtocolFee,
    uint256 _tokensOutRoyalty,
    uint256[] calldata _nftsIn
  ) external {
    _onlyPair();
    _totalFees += _tokensOutRoyalty;
  }

  // Also need to factor in new token balance and new NFT balance during calculations
  function afterSwapNFTOutPair(
    uint256 _tokensIn,
    uint256 _tokensInProtocolFee,
    uint256 _tokensInRoyalty,
    uint256[] calldata _nftsOut
  ) external {
    _onlyPair();
    _totalFees += _tokensInRoyalty;
  }

  function afterDeltaUpdate(uint128 _oldDelta, uint128 _newDelta) external {
    _onlyPair();
  }

  function afterSpotPriceUpdate(uint128 _oldSpotPrice, uint128 _newSpotPrice)
    external
  {
    _onlyPair();
  }

  function afterFeeUpdate(uint96 _oldFee, uint96 _newFee) external {
    _onlyPair();
  }

  function afterNFTWithdrawal(uint256[] calldata _nftsOut) external {
    _onlyPair();
  }

  function afterTokenWithdrawal(uint256 _tokensOut) external {
    _onlyPair();
  }

  function syncForPair(
    address pairAddress,
    uint256 _tokensIn,
    uint256[] calldata _nftsIn
  ) external {
    _onlyPair();
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


  /// @dev External function that can be used to add to total fees collected
  function externalDeposit() external payable returns (bool) {
    if (msg.value == 0) {
      revert InvalidDepositAmount();
    }
    _totalFees += msg.value;
    return true;
  }

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
    if (ownerAddr == tradePool) {
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
    // 1 - 333
    if (tokenId <= MAX_TEAM) {
      seed = keccak256(abi.encodePacked(teamMintBlockHash, tokenId));
    } else {
      seed = tokenMintInfo[tokenId].seed;
    }
    return renderer.getJsonUri(tokenId, seed);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /// @dev Public function that returns game over status
  function isGameOver() public view returns (bool) {
    return block.timestamp > endTime && _totalMinted() < MAX_SUPPLY;
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

  /// @dev Function to claim delta between price paid and final sale price
  /// NFTs must be sold out in order to use this function
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

  uint256 poolEthAmount;

  /// @dev Private function that is called once the last NFT of public sale is minted.
  function _lockItIn() private {
    if (lockedIn) {
      revert AlreadyLocked();
    }
    lockedIn = true;
    // Get available funds minus refunds
    uint256 totalAvailableEth = (_totalMinted() - MAX_TEAM) * finalCost;

    poolEthAmount = finalCost * 100;

    Address.sendValue(payable(owner), totalAvailableEth - poolEthAmount);
    lpMintBlockHash = blockhash(block.number - 1);
  }

  /// @dev Initializing pool on SudoSwap
  function _initSudoPool() internal {
    poolInitialized = true;
    uint256[] memory empty = new uint256[](0);
    tradePool = address(
      IPairFactoryLike(SUDO_FACTORY).createPairERC721ETH(
        IERC721(address(this)),
        ICurve(LINEAR_ADDRESS),
        payable(address(this)),
        LSSVMPair.PoolType.TRADE,
        uint128(finalCost),
        // set fee to 0 use royalty standard to specify fees
        0,
        uint128(finalCost),
        address(0),
        empty,
        // Hook
        address(this),
        // Referral
        address(0)
      )
    );
    _mint(tradePool, 100);
    (bool sent, bytes memory data) = tradePool.call{ value: poolEthAmount }("");
    require(sent, "Failed to send Ether");
  }

  function initSudoPool() public onlyOwner nonReentrant {
    if (poolInitialized) {
      revert PoolInitialized();
    }
    if (!lockedIn) {
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
    if (lockedIn) {
      revert SoldOut();
    }
    if (block.timestamp > endTime) {
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

  receive() external payable virtual {
    emit PaymentReceived(msg.sender, msg.value);
  }

  fallback() external payable {
    emit PaymentReceived(msg.sender, msg.value);
  }
}

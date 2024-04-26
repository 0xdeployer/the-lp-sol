// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC721A } from "ERC721A/interfaces/IERC721A.sol";
import { ud } from "@prb/math/UD60x18.sol";
import { IRouter } from "aerodrome/interfaces/IRouter.sol";

interface IFloaties {
  struct BuyWithPermitArgs {
    bytes floatyHash;
    uint256 floatyAmount;
    uint256 totalCost;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 tnFee;
    uint256 tnDeadline;
    uint8 tnV;
    bytes32 tnR;
    bytes32 tnS;
  }

  struct Floaty {
    bytes floatyHash;
    address tokenAddress;
    uint256 tokenPerFloaty;
  }
}

contract Floaties is IFloaties, Owned, Initializable {
  uint256 private locked;
  address public tn100x;
  uint256 public staticFee;
  // 0x833589fcd6edb6e08f4c7c32d4f71b54bda02913
  address public usdc;
  address collectionAccount;
  bool paused;
  mapping(bytes => Floaty) public floatyHashToFloaty;
  mapping(address => mapping(bytes => uint256)) public balanceOf;
  mapping(address => bool) signers;
  mapping(bytes => bool) paidMessage;

  modifier nonReentrant() virtual {
    require(locked == 1, "REENTRANCY");

    locked = 2;

    _;

    locked = 1;
  }

  error InvalidFloaty();
  error InvalidAmount();
  error InvalidSigner();
  error InvalidTn100xFee();
  error MessageAlreadyPaid();
  error Paused();

  event InitFloaty(
    bytes floatyHash,
    address tokenAddress,
    uint256 tokenPerFloaty
  );
  event SignerUpdate(address signer, bool value);

  constructor() Owned(address(0)) {
    _disableInitializers();
  }

  function initialize(
    address _tn100x,
    address _collectionAccount,
    uint256 _staticFee
  ) public initializer {
    locked = 1;
    paused = false;
    collectionAccount = _collectionAccount;
    tn100x = _tn100x;
    staticFee = _staticFee;
    owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  function modifySigner(address signer, bool value) public onlyOwner {
    signers[signer] = value;
    emit SignerUpdate(signer, value);
  }

  function pause(bool _paused) public onlyOwner {
    paused = _paused;
  }

  modifier notPaused() {
    if (paused) {
      revert Paused();
    }
    _;
  }

  function updateCollectionAccount(address _collectionAccount)
    public
    onlyOwner
  {
    collectionAccount = _collectionAccount;
  }

  function withdrawErc20(address token, address to) public onlyOwner {
    ERC20(token).transfer(to, ERC20(token).balanceOf(address(this)));
  }

  function updateStaticFee(uint256 fee) public onlyOwner {
    staticFee = fee;
  }

  function initFloaty(
    bytes memory floatyHash,
    address tokenAddress,
    uint256 tokenPerFloaty
  ) public onlyOwner notPaused {
    floatyHashToFloaty[floatyHash] = Floaty({
      floatyHash: floatyHash,
      tokenAddress: tokenAddress,
      tokenPerFloaty: tokenPerFloaty
    });
    emit InitFloaty(floatyHash, tokenAddress, tokenPerFloaty);
  }

  error InsufficientBalance();

  event Spend(
    address indexed from,
    address indexed to,
    bytes indexed hash,
    uint256 amount
  );

  function spend(
    address from,
    address to,
    bytes memory msgHash,
    bytes memory floatyHash,
    uint256 floatyAmount
  ) public notPaused nonReentrant {
    if (signers[msg.sender] == false) {
      revert InvalidSigner();
    }
    Floaty memory floaty = floatyHashToFloaty[floatyHash];
    if (floaty.tokenAddress == address(0)) {
      revert InvalidFloaty();
    }
    if (paidMessage[msgHash]) {
      revert MessageAlreadyPaid();
    }
    if (balanceOf[from][floatyHash] < floatyAmount) {
      revert InsufficientBalance();
    }
    paidMessage[msgHash] = true;
    balanceOf[from][floatyHash] -= floatyAmount;
    uint256 tokenAmount = floaty.tokenPerFloaty * floatyAmount;
    ERC20(floaty.tokenAddress).transfer(to, tokenAmount);
    emit Spend(from, to, floatyHash, floatyAmount);
  }

  event PurchaseFloaties(
    address indexed buyer,
    bytes indexed floatyHash,
    uint256 amount
  );

  function buyWithApproval(
    bytes memory floatyHash,
    uint256 floatyAmount,
    uint256 tokenAmount,
    uint256 tnFee,
    uint256 tnDeadline,
    uint8 tnV,
    bytes32 tnR,
    bytes32 tnS
  ) public notPaused {
    Floaty memory floaty = floatyHashToFloaty[floatyHash];
    if (floaty.tokenAddress == address(0)) {
      revert InvalidFloaty();
    }
    uint256 verifiedCost = floatyAmount * floaty.tokenPerFloaty;
    if (tokenAmount != verifiedCost) {
      revert InvalidAmount();
    }
    // calculate fee
    uint256 calculatedFee = calculateFee(floatyAmount);
    if (tnFee < calculatedFee) {
      revert InvalidTn100xFee();
    }
    ERC20(tn100x).permit(
      msg.sender,
      address(this),
      tnFee,
      tnDeadline,
      tnV,
      tnR,
      tnS
    );
    ERC20(tn100x).transferFrom(msg.sender, collectionAccount, calculatedFee);

    // transfer token to this contract from purchasers account
    ERC20(floaty.tokenAddress).transferFrom(
      msg.sender,
      address(this),
      verifiedCost
    );

    // increase balance of purchased by amount
    balanceOf[msg.sender][floatyHash] += floatyAmount;
    emit PurchaseFloaties(msg.sender, floatyHash, floatyAmount);
  }

  function calculateFee(uint256 floatyAmount) public view returns (uint256) {
    IRouter.Route[] memory routes = new IRouter.Route[](2);
    routes[0] = IRouter.Route({
      from: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
      to: 0x4200000000000000000000000000000000000006,
      stable: true,
      factory: address(0)
    });
    routes[1] = IRouter.Route({
      from: 0x4200000000000000000000000000000000000006,
      to: 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A,
      stable: false,
      factory: address(0)
    });
    uint256[] memory amount = IRouter(
      0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43
    ).getAmountsOut(staticFee, routes);
    return amount[2] * floatyAmount;
  }

  event FeeCollected(uint256 amount);

  function buyWithPermit(BuyWithPermitArgs memory args) public notPaused {
    Floaty memory floaty = floatyHashToFloaty[args.floatyHash];
    if (floaty.tokenAddress == address(0)) {
      revert InvalidFloaty();
    }
    uint256 verifiedCost = args.floatyAmount * floaty.tokenPerFloaty;
    if (args.totalCost != verifiedCost) {
      revert InvalidAmount();
    }

    // calculate fee
    uint256 calculatedFee = calculateFee(args.floatyAmount);
    if (args.tnFee < calculatedFee) {
      revert InvalidTn100xFee();
    }
    ERC20(tn100x).permit(
      msg.sender,
      address(this),
      args.tnFee,
      args.tnDeadline,
      args.tnV,
      args.tnR,
      args.tnS
    );
    ERC20(tn100x).transferFrom(msg.sender, collectionAccount, calculatedFee);

    // transfer token to this contract from purchasers account
    ERC20(floaty.tokenAddress).permit(
      msg.sender,
      address(this),
      args.totalCost,
      args.deadline,
      args.v,
      args.r,
      args.s
    );
    ERC20(floaty.tokenAddress).transferFrom(
      msg.sender,
      address(this),
      args.totalCost
    );

    // increase balance of purchased by amount
    balanceOf[msg.sender][args.floatyHash] += args.floatyAmount;
    emit PurchaseFloaties(msg.sender, args.floatyHash, args.floatyAmount);
  }

  function calculateEthToTn100x(uint256 amountIn)
    public
    view
    returns (uint256)
  {
    IRouter.Route[] memory routes = new IRouter.Route[](1);
    routes[0] = IRouter.Route({
      from: 0x4200000000000000000000000000000000000006,
      to: 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A,
      stable: false,
      factory: address(0)
    });
    uint256[] memory out = IRouter(0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43)
      .getAmountsOut(amountIn, routes);
    return out[1];
  }

  function calculateTn100xToEth(uint256 amountIn)
    public
    view
    returns (uint256)
  {
    IRouter.Route[] memory routes = new IRouter.Route[](1);
    routes[0] = IRouter.Route({
      from: 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A,
      to: 0x4200000000000000000000000000000000000006,
      stable: false,
      factory: address(0)
    });
    uint256[] memory out = IRouter(0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43)
      .getAmountsOut(amountIn, routes);
    return out[1];
  }

  event EthForFloaty(bytes data);

  function swapEthForTn100x(uint256 amountOutMin)
    public
    payable
    returns (uint256[] memory amounts)
  {
    IRouter.Route[] memory routes = new IRouter.Route[](1);
    routes[0] = IRouter.Route({
      from: 0x4200000000000000000000000000000000000006,
      to: 0x5B5dee44552546ECEA05EDeA01DCD7Be7aa6144A,
      stable: false,
      factory: address(0)
    });
    return
      IRouter(0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43).swapExactETHForTokens{
        value: msg.value
      }(amountOutMin, routes, address(this), block.timestamp + 5 minutes);
  }

  function swapEthForFloaties(uint256 amountOutMin, bytes memory data) public payable {
    if (amountOutMin < 100 ether) {
      revert InvalidAmount();
    }
    uint256[] memory amounts = swapEthForTn100x(amountOutMin);
    uint256 tn100xReceived = amounts[1];
    uint256 numberOfFloaties = tn100xReceived / 100 ether;
    uint256 delta = tn100xReceived - (numberOfFloaties * 100 ether);
    if (delta > 0) {
      ERC20(tn100x).transfer(msg.sender, delta);
    }

    balanceOf[msg.sender][hex"f09fa684"] += numberOfFloaties;
    emit PurchaseFloaties(msg.sender, hex"f09fa684", numberOfFloaties);
    emit EthForFloaty(data);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Owned } from "solmate/auth/Owned.sol";

contract Buy is Owned {
  uint public price;
  address public paymentToken;
  address public receiver;
  
  event Purchase(address indexed buyer, uint amount, string uuid);
  event ReceiverUpdated(address receiver);

  constructor(
    uint _price,
    address _paymentToken
  ) Owned(msg.sender) {
    price = _price;
    paymentToken = _paymentToken;
    receiver = msg.sender;
  }

  function updateReceiver(address _receiver) public onlyOwner {
    receiver = _receiver;
  }

  function updateCost(uint amount) public onlyOwner {
    price = amount;
  }

  function updatePaymentToken(address _paymentToken) public onlyOwner {
    paymentToken = _paymentToken;
  }

  function buy(string memory uuid, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
    ERC20(paymentToken).permit(msg.sender, address(this), price, deadline, v, r, s);
    ERC20(paymentToken).transferFrom(msg.sender, receiver, price);
    emit Purchase(msg.sender, price, uuid);
  }
}

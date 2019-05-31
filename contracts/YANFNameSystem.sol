pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract YANFNameSystem is Ownable, Pausable {

  mapping(address => string) private database;
  mapping(address => uint) private expirebase;

  address payable revenueReceiver;

  uint constant YEAR_COST = 10 finney;

  function setRevenueReceiver(address payable who) public onlyOwner {
    revenueReceiver = who;
  }

  function getName(address who)
    public
    view
    returns(string memory)
  {
    if (expirebase[who] < now)
    {
      return "EXPIRED";
    }
    return database[who];
  }

  function buyName(string memory name)
    public
    payable
    returns(bool)
  {
    if (msg.value >= YEAR_COST && expirebase[msg.sender] < now)
    {
      database[msg.sender] = name;
      expirebase[msg.sender] = now + (4 weeks  * SafeMath.div(msg.value, YEAR_COST));
    }
  }

  function getRevenue()
    public
    onlyOwner
    returns(bool)
  {
    revenueReceiver.transfer(address(this).balance);
  }

}

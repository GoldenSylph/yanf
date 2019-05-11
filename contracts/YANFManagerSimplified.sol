pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract YANFManagerSimplified is Ownable, Pausable {

  struct Article {
    string title;
    string contentHash;
    uint price;
  }

  struct Feed {
    uint articleCount;
    mapping(uint => Article) articles;
  }

  event Bought(address feedOwner, uint articleIndex, address sender, bool result, uint price, uint givenAmount);
  event Withdraw(address who, uint amount, bool success);

  mapping(address => Feed) private feeds;

  mapping(address => mapping(address => mapping(uint => bool))) customers;

  mapping(address => uint) balances;

  uint private publishPrice = 1 finney;

  function getYanfBalance()
    public
    view
    returns(uint)
  {
    return balances[msg.sender];
  }

  function withdraw(uint amount)
    public
  {
    if (amount <= balances[msg.sender]) {
      balances[msg.sender] = SafeMath.sub(balances[msg.sender], amount);
      msg.sender.transfer(amount);
      emit Withdraw(msg.sender, amount, true);
    } else {
      emit Withdraw(msg.sender, amount, false);
    }
  }

  function getArticleCount(address feedOwner)
    public
    view
    returns(uint)
  {
    return feeds[feedOwner].articleCount;
  }

  function getArticleTitleByIndex(address feedOwner, uint index)
    public
    view
    returns(string memory)
  {
    return feeds[feedOwner].articles[index].title;
  }

  function getArticleContentHashByIndex(address feedOwner, uint index)
    public
    view
    returns(string memory)
  {
    if (feeds[feedOwner].articles[index].price == 0 ||
        customers[msg.sender][feedOwner][index]) {
      return feeds[feedOwner].articles[index].contentHash;
    }
    return "FORBIDDEN";
  }

  function buy(address feedOwner, uint index)
    public
    payable
  {
    uint price = feeds[feedOwner].articles[index].price;
    if (msg.value >= price && price > 0) {
      customers[msg.sender][feedOwner][index] = true;
      emit Bought(feedOwner, index, msg.sender, true, price, msg.value);
      balances[feedOwner] = SafeMath.add(balances[feedOwner], msg.value);
    }
    emit Bought(feedOwner, index, msg.sender, false, price, msg.value);
  }

  function getArticlePriceByIndex(address feedOwner, uint index)
    public
    view
    returns(uint)
  {
    return feeds[feedOwner].articles[index].price;
  }

  function publish(string memory title, string memory contentHash, uint price)
    public
    payable
    returns(bool)
  {
    if (msg.value < publishPrice) {
      return false;
    }
    if (price > 0) {
      customers[msg.sender][msg.sender][feeds[msg.sender].articleCount] = true;
    }
    feeds[msg.sender].articles[feeds[msg.sender].articleCount] = Article(title, contentHash, price);
    feeds[msg.sender].articleCount = SafeMath.add(feeds[msg.sender].articleCount, 1);
    balances[owner()] = SafeMath.add(balances[owner()], msg.value);
    return true;
  }

  function () external payable {}

}

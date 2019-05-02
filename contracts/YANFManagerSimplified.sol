pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./YANFToken.sol";

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

  mapping(address => Feed) public feeds;

  mapping(address => mapping(address => mapping(uint => bool))) customers;

  uint private publishPrice = 1 finney;

  YANFToken private tokenContract =
    new YANFToken("Yet Another News Feed Token", "YANF", 18);


  function sendFees(address payable who, uint amount)
    public
    onlyOwner
  {
    who.transfer(amount);
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
    feeds[msg.sender].articles[feeds[msg.sender].articleCount] = Article(title, contentHash, price);
    feeds[msg.sender].articleCount = SafeMath.add(feeds[msg.sender].articleCount, 1);
  }

  function () external payable {}

}

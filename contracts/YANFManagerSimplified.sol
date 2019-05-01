pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract YANFManagerSimplified is Ownable, Pausable {

  struct Article {
    string title;
    string contentHash;
  }

  struct Feed {
    uint articleCount;
    mapping(uint => Article) articles;
  }

  mapping(address => Feed) public feeds;
  uint private publishPrice = 1 finney;

  address payable feeHolder;

  function setFeeReceiver(address payable feeReceiver)
    public
    onlyOwner
    returns(bool)
  {
    feeHolder = feeReceiver;
  }

  function sendFees()
    public
    onlyOwner
    returns(bool)
  {
    feeHolder.transfer(address(this).balance);
    return true;
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
    return feeds[feedOwner].articles[index].contentHash;
  }

  function publish(string memory title, string memory contentHash)
    public
    payable
    returns(bool)
  {
    if (msg.value < publishPrice) {
      return false;
    }
    feeds[msg.sender].articles[feeds[msg.sender].articleCount] = Article(title, contentHash);
    feeds[msg.sender].articleCount = SafeMath.add(feeds[msg.sender].articleCount, 1);
  }

}

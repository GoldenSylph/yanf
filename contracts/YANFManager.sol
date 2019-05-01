pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./YANFToken.sol";

contract YANFManager is Ownable, Pausable {

  struct Feed {
    uint articlesCount;
    mapping(uint => Article) articles;
    bool initialized;
  }

  struct Article {
    string title;
    string content_hash;
    bool initialized;
    mapping(address => uint) coauthors;
    mapping(uint => address) coauthorsRanks;
    uint coauthorsCount;
    mapping (uint => address) customers;
    uint customersCount;
    uint price;
  }

  mapping(uint => Feed) private feeds;
  mapping(address => uint) private feedsIndexes;
  uint private feedsCount = 0;

  uint private constant MAX_WINDOW = 1000;
  uint public constant fee = 1 finney;

  address payable feeHolder;

  YANFToken private tokenContract =
    new YANFToken("Yet Another News Feed Token", "YANF", 18);

  function setFeeReceiver(address payable who)
    public
    onlyOwner
    whenNotPaused
  {
    feeHolder = who;
  }

  function getFeeReceiver()
    public
    view
    onlyOwner
    whenNotPaused
    returns(address)
  {
    return feeHolder;
  }

  function publish(string memory title, string memory content_hash,
      address[] memory coauthors, uint[] memory parts, uint price)
    public
    whenNotPaused
    returns(bool)
  {
    if (coauthors.length != parts.length) return false;

    uint partsSum = 0;
    for (uint i = 0; i < parts.length; i = SafeMath.add(i, 1)) {
      partsSum = SafeMath.add(partsSum, parts[i]);
    }
    if (partsSum > price) {
      return false;
    }

    if (!feeds[feedsIndexes[msg.sender]].initialized) {
      feedsCount = SafeMath.add(feedsCount, 1);
      feedsIndexes[msg.sender] = SafeMath.sub(feedsCount, 1);
      feeds[feedsIndexes[msg.sender]] = Feed(0, true);
      feeds[feedsIndexes[msg.sender]].articlesCount = 1;
      feeds[feedsIndexes[msg.sender]].articles[0] = Article(title, content_hash, true, coauthors.length, 0, price);
    } else {
      uint oldArticlesCount = feeds[feedsIndexes[msg.sender]].articlesCount;
      feeds[feedsIndexes[msg.sender]].articlesCount = SafeMath.add(oldArticlesCount, 1);
      feeds[feedsIndexes[msg.sender]].articles[oldArticlesCount] = Article(title, content_hash, true, coauthors.length, 0, price);
    }
    return true;
  }

  function setCoauthorPart(address who, uint articleIndex, uint part)
    public
    whenNotPaused
    returns(bool)
  {
    uint feedIndexOfSender = feedsIndexes[msg.sender];
    if (who == address(0)
        || !feeds[feedIndexOfSender].initialized
        || part >= feeds[feedIndexOfSender].articles[articleIndex].price) {
      return false;
    }
    if (feeds[feedIndexOfSender].articles[articleIndex].coauthors[who] == 0) {
      uint oldCoauthorsCount = feeds[feedIndexOfSender].articles[articleIndex].coauthorsCount;
      feeds[feedIndexOfSender].articles[articleIndex].coauthorsCount = SafeMath.add(oldCoauthorsCount, 1);
      feeds[feedIndexOfSender].articles[articleIndex].coauthorsRanks[oldCoauthorsCount] = who;
    }
    feeds[feedIndexOfSender].articles[articleIndex].coauthors[who] = part;
    return true;
  }

  function searchArticlesByChosenPredicate
    (
      uint feedIndex, uint articleOffset,
      string memory title, uint price, address coauthor,
      bool titlePredicate, bool pricePredicate, bool coauthorPredicate
    )
    public
    view
    whenNotPaused
    returns(uint[] memory)
  {
    uint[] memory resultArticlesIndexes = new uint[](MAX_WINDOW);
    uint currentArticleIndexCount = 0;
    for (uint j = articleOffset; j < feeds[feedIndex].articlesCount; j = SafeMath.add(j, 1)) {
      if (
        (stringEquals(feeds[feedIndex].articles[j].title, title) && titlePredicate) ||
        (articleHasEqualOrLesserPrice(feedIndex, j, price) && pricePredicate) ||
        (articleContainsCoauthor(feedIndex, j, coauthor) && coauthorPredicate)
      ) {
        resultArticlesIndexes[currentArticleIndexCount] = j;
        currentArticleIndexCount = SafeMath.add(currentArticleIndexCount, 1);
        if (currentArticleIndexCount > MAX_WINDOW) {
          j = SafeMath.add(feeds[feedIndex].articlesCount, 1);
        }
      }
    }
    return resultArticlesIndexes;
  }

  function searchFeedByAuthor(address author)
    public
    view
    whenNotPaused
    returns(uint feedIndex)
  {
    return feedsIndexes[author];
  }

  function sendContractFees()
    public
    onlyOwner
    whenNotPaused
    returns(bool)
  {
    feeHolder.transfer(address(this).balance);
    return true;
  }

  function buy(address author, uint feed, uint article)
    public
    payable
    whenNotPaused
    returns(bool)
  {
    if (feedsIndexes[author] != feed) {
      return false;
    }
    if (!feeds[feed].initialized || !feeds[feed].articles[article].initialized) {
      return false;
    }
    if (feeds[feed].articles[article].price > 0) {
      if (msg.value >= feeds[feed].articles[article].price + fee) {
        feeds[feed].articles[article].customers[feeds[feed].articles[article].customersCount] = msg.sender;
        feeds[feed].articles[article].customersCount += 1;
        uint authorPrice = feeds[feed].articles[article].price;
        for (uint i = 0; i < feeds[feed].articles[article].coauthorsCount; i = SafeMath.add(i, 1)) {
          uint currentCoauthorPrice = feeds[feed].articles[article].coauthors[feeds[feed].articles[article].coauthorsRanks[i]];
          authorPrice = SafeMath.sub(authorPrice, currentCoauthorPrice);
          tokenContract.mint(feeds[feed].articles[article].coauthorsRanks[i], currentCoauthorPrice);
        }
        tokenContract.mint(author, authorPrice);
        return true;
      } else {
        return false;
      }
    } else {
      feeds[feed].articles[article].customers[feeds[feed].articles[article].customersCount] = msg.sender;
      feeds[feed].articles[article].customersCount += 1;
      return true;
    }
  }

  function receiveRoyalty()
    public
    whenNotPaused
    returns(bool)
  {
    if (tokenContract.balanceOf(msg.sender) == 0) return true;
    msg.sender.transfer(tokenContract.balanceOf(msg.sender));
    tokenContract.burnFrom(msg.sender, tokenContract.balanceOf(msg.sender));
  }

  function getArticleTitle(uint feedIndex, uint articleIndex)
    public
    view
    whenNotPaused
    returns(string memory)
  {
    return feeds[feedIndex].articles[articleIndex].title;
  }

  function getArticleContentHash(uint feedIndex, uint articleIndex)
    public
    view
    whenNotPaused
    returns(string memory)
  {
    if (feedsIndexes[msg.sender] == feedIndex
      || isCustomerInArticle(feedIndex, articleIndex, msg.sender)
      || feeds[feedIndex].articles[articleIndex].coauthors[msg.sender] > 0
    ) {
      return feeds[feedIndex].articles[articleIndex].content_hash;
    } else {
      return "FORBIDDEN";
    }
  }

  function getArticlePrice(uint feedIndex, uint articleIndex)
    public
    view
    whenNotPaused
    returns(uint)
  {
    return feeds[feedIndex].articles[articleIndex].price;
  }

  function getArticleCoauthorsCount(uint feedIndex, uint articleIndex)
    public
    view
    whenNotPaused
    returns(uint)
  {
    return feeds[feedIndex].articles[articleIndex].coauthorsCount;
  }

  function getArticleCoauthor(uint feedIndex, uint articleIndex, uint coauthorRank)
    public
    view
    whenNotPaused
    returns(address)
  {
    return feeds[feedIndex].articles[articleIndex].coauthorsRanks[coauthorRank];
  }

  function stringEquals(string memory a, string memory b)
    private
    view
    whenNotPaused
    returns(bool)
  {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  function articleContainsCoauthor(uint feed, uint article, address who)
    private
    view
    whenNotPaused
    returns(bool)
  {
    return feeds[feed].articles[article].coauthors[who] != 0;
  }

  function articleHasEqualOrLesserPrice(uint feed, uint article, uint price)
    private
    view
    whenNotPaused
    returns(bool)
  {
    return feeds[feed].articles[article].price <= price;
  }

  function isCustomerInArticle(uint feedIndex, uint articleIndex, address customer)
    private
    view
    whenNotPaused
    returns(bool)
  {
    for (uint i = 0; i < feeds[feedIndex].articles[articleIndex].customersCount; i = SafeMath.add(i, 1)) {
      if (feeds[feedIndex].articles[articleIndex].customers[i] == customer) {
        return true;
      }
    }
    return false;
  }
}

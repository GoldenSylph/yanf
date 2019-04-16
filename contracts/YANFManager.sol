pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./YANFToken.sol";

contract YANFManager is Ownable, Pausable {

  struct Feed {
    uint articlesCount;
    mapping(uint => Article) articles;
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

  address payable feeReceiver;

  YANFToken private tokenContract =
    new YANFToken("Yet Another News Feed Token", "YANF", 18);

  function setFeeReceiver(address payable who) public onlyOwner {
    feeReceiver = who;
  }

  function publish(string memory title, string memory content_hash, address[] memory coauthors, uint[] memory parts, uint price)
    public
    returns(bool)
  {
    if (coauthors.length != parts.length) return false;

    uint partsSum = 0;
    for (uint i = 0; i < parts.length; i = SafeMath.add(i, 1)) {
      partsSum += parts[i];
    }
    if (partsSum > price) {
      return false;
    }

    if (feedsIndexes[msg.sender] == 0) {
      feedsCount = SafeMath.add(feedsCount, 1);
      uint firstFeedIdx = SafeMath.sub(feedsCount, 1);
      uint firstArticleIdx = SafeMath.sub(feeds[firstFeedIdx].articlesCount, 1);
      feeds[firstFeedIdx].articlesCount = 1;
      feeds[firstFeedIdx].articles[firstArticleIdx] = Article(title, content_hash, true, coauthors.length, 0, price);
      for (uint i = 0; i < coauthors.length; i = SafeMath.add(i, 1)) {
        feeds[firstFeedIdx].articles[firstArticleIdx].coauthors[coauthors[i]] = parts[i];
        feeds[firstFeedIdx].articles[firstArticleIdx].coauthorsRanks[i] = coauthors[i];
      }
      feedsIndexes[msg.sender] = firstFeedIdx;
    } else {
      uint newArticleCount = SafeMath.add(feeds[feedsIndexes[msg.sender]].articlesCount, 1);
      feeds[feedsIndexes[msg.sender]].articlesCount = newArticleCount;
      feeds[feedsIndexes[msg.sender]].articles[SafeMath.sub(newArticleCount, 1)] = Article(title, content_hash, true, coauthors.length, 0, price);
      for (uint i = 0; i < coauthors.length; i = SafeMath.add(i, 1)) {
        feeds[feedsIndexes[msg.sender]].articles[SafeMath.sub(newArticleCount, 1)].coauthors[coauthors[i]] = parts[i];
        feeds[feedsIndexes[msg.sender]].articles[SafeMath.sub(newArticleCount, 1)].coauthorsRanks[i] = coauthors[i];
      }
    }
    return true;
  }

  function setCoauthorPart(address who, uint articleIndex, uint part)
    public
    returns(bool)
  {
    if (who == address(0) || feedsIndexes[msg.sender] == 0
        || feeds[feedsIndexes[msg.sender]].articlesCount == 0
        || part >= feeds[feedsIndexes[msg.sender]].articles[articleIndex].price) {
      return false;
    }
    feeds[feedsIndexes[msg.sender]].articles[articleIndex].coauthors[who] = part;
    return true;
  }

  function addCoauthorPart(address who, uint articleIndex, uint part)
    public
    returns(bool)
  {
    if (!setCoauthorPart(who, articleIndex, part)) {
      return false;
    }
    feeds[feedsIndexes[msg.sender]].articles[articleIndex].coauthorsCount =
      SafeMath.add(feeds[feedsIndexes[msg.sender]].articles[articleIndex].coauthorsCount, 1);
    feeds[feedsIndexes[msg.sender]].articles[articleIndex]
      .coauthorsRanks[feeds[feedsIndexes[msg.sender]].articles[articleIndex].coauthorsCount] = who;
    return true;
  }

  function searchArticlesByTitle(string memory title)
    public
    view
    returns(uint[] memory resArticlesIndexes, uint[] memory resFeedsIndexes)
  {
    uint[] memory resultArticlesIndexes = new uint[](MAX_WINDOW);
    uint[] memory resultFeedsIndexes = new uint[](MAX_WINDOW);
    uint currentArticleIndexCount = 0;
    uint currentFeedIndexCount = 0;
    for (uint i = 0; i <= SafeMath.sub(feedsCount, 1); i = SafeMath.add(i, 1)) {
      for (uint j = 0; j < feeds[i].articlesCount; j = SafeMath.add(j, 1)) {
        if (stringEquals(feeds[i].articles[j].title, title)) {
          resultFeedsIndexes[currentFeedIndexCount] = i;
          currentFeedIndexCount = SafeMath.add(currentFeedIndexCount, 1);
          resultArticlesIndexes[currentArticleIndexCount] = j;
          currentArticleIndexCount = SafeMath.add(currentArticleIndexCount, 1);
        }
      }
    }
    return (resultArticlesIndexes, resultFeedsIndexes);
  }

  function searchArticleByCoauthor(address coauthor)
    public
    view
    returns(uint[] memory resArticlesIndexes, uint[] memory resFeedsIndexes)
  {
    uint[] memory resultArticlesIndexes = new uint[](MAX_WINDOW);
    uint[] memory resultFeedsIndexes = new uint[](MAX_WINDOW);
    uint currentArticleIndexCount = 0;
    uint currentFeedIndexCount = 0;
    for (uint i = 0; i <= SafeMath.sub(feedsCount, 1); i = SafeMath.add(i, 1)) {
      for (uint j = 0; j < feeds[i].articlesCount; j = SafeMath.add(j, 1)) {
        if (articleContainsCoauthor(i, j, coauthor)) {
          resultFeedsIndexes[currentFeedIndexCount] = i;
          currentFeedIndexCount = SafeMath.add(currentFeedIndexCount, 1);
          resultArticlesIndexes[currentArticleIndexCount] = j;
          currentArticleIndexCount = SafeMath.add(currentArticleIndexCount, 1);
        }
      }
    }
    return (resultArticlesIndexes, resultFeedsIndexes);
  }

  function searchArticleByPrice(uint price)
    public
    view
    returns(uint[] memory resArticlesIndexes, uint[] memory resFeedsIndexes)
  {
    uint[] memory resultArticlesIndexes = new uint[](MAX_WINDOW);
    uint[] memory resultFeedsIndexes = new uint[](MAX_WINDOW);
    uint currentArticleIndexCount = 0;
    uint currentFeedIndexCount = 0;
    for (uint i = 0; i <= SafeMath.sub(feedsCount, 1); i = SafeMath.add(i, 1)) {
      for (uint j = 0; j < feeds[i].articlesCount; j = SafeMath.add(j, 1)) {
        if (articleHasEqualOrLesserPrice(i, j, price)) {
          resultFeedsIndexes[currentFeedIndexCount] = i;
          currentFeedIndexCount = SafeMath.add(currentFeedIndexCount, 1);
          resultArticlesIndexes[currentArticleIndexCount] = j;
          currentArticleIndexCount = SafeMath.add(currentArticleIndexCount, 1);
        }
      }
    }
    return (resultArticlesIndexes, resultFeedsIndexes);
  }

  function searchFeedByAuthor(address author)
    public
    view
    returns(uint feedIndex)
  {
    return feedsIndexes[author];
  }

  function sendContractFees()
    onlyOwner
    public
    returns(bool)
  {
    feeReceiver.transfer(address(this).balance);
    return true;
  }

  function buy(uint feed, uint article)
    public
    payable
    returns(bool)
  {
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
        tokenContract.mint(msg.sender, authorPrice);
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
    returns(bool)
  {
    if (tokenContract.balanceOf(msg.sender) == 0) return true;
    msg.sender.transfer(tokenContract.balanceOf(msg.sender));
    tokenContract.burnFrom(msg.sender, tokenContract.balanceOf(msg.sender));
  }

  function stringEquals(string memory a, string memory b) private pure returns(bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  function articleContainsCoauthor(uint feed, uint article, address who) private view returns(bool) {
    return feeds[feed].articles[article].coauthors[who] != 0;
  }

  function articleHasEqualOrLesserPrice(uint feed, uint article, uint price) private view returns(bool) {
    return feeds[feed].articles[article].price <= price;
  }

}

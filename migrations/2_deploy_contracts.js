var YANFManagerSimplifiedContract = artifacts.require("./YANFManagerSimplified.sol");
var SafeMathLibrary = artifacts.require("openzeppelin-solidity/contracts/math/SafeMath.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMathLibrary);
  deployer.link(SafeMathLibrary, YANFManagerSimplifiedContract);
  deployer.deploy(YANFManagerSimplifiedContract);
};

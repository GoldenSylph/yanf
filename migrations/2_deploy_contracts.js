/*var YANFManagerContract = artifacts.require("./YANFManager.sol");
var YANFNameSystemContract = artifacts.require("./YANFNameSystem.sol");
var SafeMathLibrary = artifacts.require("openzeppelin-solidity/contracts/math/SafeMath.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMathLibrary);
  deployer.link(SafeMathLibrary, YANFManagerContract);
  deployer.link(SafeMathLibrary, YANFNameSystemContract);
  deployer.deploy(YANFManagerContract);
  deployer.deploy(YANFNameSystemContract);
};*/

var YANFManagerSimplifiedContract = artifacts.require("./YANFManagerSimplified.sol");
var SafeMathLibrary = artifacts.require("openzeppelin-solidity/contracts/math/SafeMath.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMathLibrary);
  deployer.link(SafeMathLibrary, YANFManagerSimplifiedContract);
  deployer.deploy(YANFManagerSimplifiedContract);
};

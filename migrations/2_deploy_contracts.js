var YANFManagerSimplifiedContract = artifacts.require("./YANFManagerSimplified.sol");
var SafeMathLibrary = artifacts.require("openzeppelin-solidity/contracts/math/SafeMath.sol");

module.exports = async function(deployer) {
  await deployer.deploy(SafeMathLibrary);
  await deployer.link(SafeMathLibrary, YANFManagerSimplifiedContract);
  await deployer.deploy(YANFManagerSimplifiedContract);
};

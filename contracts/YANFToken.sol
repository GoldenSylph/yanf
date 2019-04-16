pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract YANFToken is ERC20Detailed, ERC20Burnable, ERC20Pausable, Ownable {

  constructor(string memory name, string memory symbol, uint8 decimals) ERC20Detailed(name, symbol, decimals) public {}

  function transfer(address to, uint256 value) public whenNotPaused onlyOwner returns (bool) {
    return super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value) public whenNotPaused onlyOwner returns (bool) {
    return super.transferFrom(from, to, value);
  }

  function approve(address spender, uint256 value) public whenNotPaused onlyOwner returns (bool) {
    return super.approve(spender, value);
  }

  function increaseAllowance(address spender, uint addedValue) public whenNotPaused onlyOwner returns (bool) {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused onlyOwner returns (bool) {
    return super.decreaseAllowance(spender, subtractedValue);
  }

  function mint(address to, uint256 value) public whenNotPaused onlyOwner returns (bool) {
    _mint(to, value);
    return true;
  }

  function burn(uint256 value) whenNotPaused onlyOwner public {
    super.burnFrom(msg.sender, value);
  }

  function burnFrom(address from, uint256 value) whenNotPaused onlyOwner public {
    super.burnFrom(from, value);
  }
}

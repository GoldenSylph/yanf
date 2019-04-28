pragma solidity ^0.5.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/YANFManager.sol";

contract TestYANFManagerSetCoauthorPart {

  address[] coauthors;
  uint[] parts;

  function afterEach() public {
    delete coauthors;
    delete parts;
  }

  function testSettingFeeReceiver() public {
    YANFManager manager = new YANFManager();
    address payable feeReceiver = 0x572E01D0B43D94D3B029378A60A897408d588820;
    manager.setFeeReceiver(feeReceiver);
    Assert.equal(manager.getFeeReceiver(), feeReceiver, "Fee receiver must be set up.");
  }

  function testSetCoauthorPart() public {
    YANFManager manager = new YANFManager();
    address payable feeReceiver = 0x572E01D0B43D94D3B029378A60A897408d588820;
    manager.setFeeReceiver(feeReceiver);

    string memory title = "The test publishing";
    string memory contentHash = "QmRW3V9znzFW9M5FYbitSEvd5dQrPWGvPvgQD6LM22Tv8D";

    coauthors.push(0x592b6AF9C4d7a1cC146d68C840c77c60f7B80a90);
    coauthors.push(0x58D13B5A3C3AEa873f815C702D42becBca2B04FA);
    coauthors.push(0x5c1b29698F1e0C19ddB025dF2d55cD58C2415c1c);
    uint price = 1 ether;

    parts.push(price / 4);
    parts.push(price / 4);
    parts.push(price / 4);

    manager.publish(title, contentHash, coauthors, parts, price);

    address newCoauthor = 0x2B9DF6fb39974f16d48678DabE956ea8B40ace1A;
    uint articleIndex = 0;
    uint part = price / 4;

    bool result = manager.setCoauthorPart(newCoauthor, articleIndex, part);
    Assert.equal(result, true, "Coauthor part must be added");
  }

}

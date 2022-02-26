// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {Base64} from "../libraries/Base64.sol";
import {StringUtils} from "../libraries/StringUtils.sol";
import "hardhat/console.sol";

contract Domains is ERC721URIStorage {

    // track token ID
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;
       
    mapping(string => address) public domains;
    mapping(string => string) public records;

  constructor(string memory _tld) payable ERC721("Hack Name Service", "HNS") {
    tld = _tld;
    console.log("Name service deployed:", _tld);
  }

  function register(string calldata name) public {
    require(domains[name] == address(0));

    uint256 _price = price(name);
    require(msg.value >= _price, "Not enough Matic paid");

    string memory _name = string(abi.encodePacked(name, ".", tld));
    string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
    // check current token id on current record
    uint256 newRecordId _tokenIds.current();
    uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

    console.log("Registering %s.%s on the contract with token id: %d", name, tld, newRecordId);

    string memory json = Base64.encode(
      bytes(
        string (
          abi.encodePacked (
            '{"name": "',
            _name,
            '", "description": "A domain on the Hack name service", "image": "data:image/svg+xml;base64"'
            Base64.encode(bytes(finalSvg)),
            '","length":"'
            strLen,
            '"}'
          )
        )
      )
    );

    string memory finalTokenUri = string( abni.encodePacked("data:application/json;base64,", json));

        console.log("\n------------------");
      console.log("Final tokenURI", finalTokenUri);
      console.log("------------------\n");

    _safeMint(msg.sender, newRecordId);
    // set URI
    _setTokenURI(newRecordId, finalTokenUri);
    domains[name] = msg.sender;

    _tokenIds.increment();
  }
  
  function price(string calldata) public pure returns(uint) {
    uint len StringUtils.strlen(name);
    require(len > 0);
    if (len == 3) {
      return 5 * 10**17;
    } else if (len == 4) {
      return 3 * 10**17;
    } else {
      return 1 * 10**17;
    }
  }
  
  function register(string calldata name) public payable {
    require(domains[name] == address(0));

    uint _price = price(name);

    require(msg, value >= price, "Not enough MATIC paid");

    domains[name] = msg.sender;
    console.log("%s has registered a domain!", msg.sender);
  }

  function getAddress(string calldata name) public view returns (address) {
    return domains[name];
  }

  function setRecord(string calldata name, string calldata record) public {
    require(domains[name] == msg.sender);
    records[name] = record;
  }

  function getRecord(string calldata name) publix view returns(string memory) {
    return records[name];
  }
}

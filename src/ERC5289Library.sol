/// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./interfaces/IERC5289Library.sol";

contract ERC5289Library is IERC165, IERC5289Library {
    uint16 private counter = 0;
    mapping(uint16 => string) private uris;
    mapping(uint16 => mapping(address => uint64)) signedAt;

    constructor() { }

    function getTotalSupplyDocument() public view returns ( uint16 ){ return counter; }

    function registerDocument(string memory uri) public returns (uint16) {
        uris[counter] = uri;
        return counter++;
    }

    function legalDocument(uint16 documentId) public view returns (string memory uri) {
        return uris[documentId];
    }

    function documentSigned(address user, uint16 documentId) public view returns (bool isSigned) {
        return signedAt[documentId][user] != 0;
    }

    function documentSignedAt(address user, uint16 documentId) public view returns (uint64 timestamp) {
        return signedAt[documentId][user];
    }

    function signDocument(address signer, uint16 documentId) public {
        require(signer == msg.sender, "invalid user");

        signedAt[documentId][msg.sender] = uint64(block.timestamp);

        emit DocumentSigned(msg.sender, documentId);
    }

    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return _interfaceId == type(IERC5289Library).interfaceId;
    }
}
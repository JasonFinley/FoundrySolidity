/// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./interfaces/IERC5289Library.sol";

contract ERC5289Library is IERC165, IERC5289Library {
    uint16 private counter = 0;
    mapping(uint16 => string) private uris;
    mapping(uint16 => mapping(address => uint64)) signedAt;

    event SignedWrongCall(address indexed caller, address indexed signer, uint16 indexed documentId);

    constructor() {}

    function getTotalSupplyDocument() public view returns ( uint16 ){ return counter; }
    function getStartDocumentID() public pure returns ( uint16 ){ return 1; }

    function _registerDocument(string memory uri) internal returns (uint16) {

        require( ++counter < type(uint16).max, "ERC5289Library : over register" );

        uris[ counter ] = uri;
        return counter;
    }

    function _signDocument( address signer, uint16 documentId ) internal {

        require( signer != address(0), "signDocument : user isnt zero " );
        require( documentId != 0, "signDocument : id isnt zero " );
        require( documentId <= counter, "signDocument : id is over counter" );

        signedAt[documentId][signer] = uint64(block.timestamp);

        emit DocumentSigned(signer, documentId);
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

    function signDocument( address signer, uint16 documentId) public {
        //require( false, "signDocument : dont use this function" );
        emit SignedWrongCall( msg.sender, signer, documentId );
    }

    function supportsInterface(bytes4 _interfaceId) public pure virtual override returns (bool) {
        return _interfaceId == type(IERC5289Library).interfaceId;
    }
}
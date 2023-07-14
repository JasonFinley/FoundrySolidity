// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./RoleProfit.sol";
import "./ERC5289Library.sol";

contract SoundsToken is ERC1155, ReentrancyGuard, ERC5289Library, RoleProfit, Ownable {

    struct SoundInfo {
        uint256 ReleaseSupply;
        uint256 ReleaseCounter;
        uint256 OnceMax;
        string BaseURI;
    }

    uint256 public _total_supply = 0;
    uint256 private _base_price = 1000;
    uint256 public _MAX_TOTAL_SUPPLY;
    string public _name;
    string public _symbol;

    // id => sound info
    mapping( uint256 => SoundInfo ) private _releaseSoundInfo;

    // id => copyright price
    mapping( uint16 => uint256 ) private _copyrightAmount;
    mapping( address => mapping( uint256 => uint16 ) ) private _userCopyright;
    
    event CreateSound( address indexed owner, uint256 indexed id, string uriSound );

    constructor( string memory name, string memory symbol, uint256 maxTotalSupply, address initOwner ) Ownable( initOwner ) ERC1155("") {
        _name = name;
        _symbol = symbol;
        _MAX_TOTAL_SUPPLY = maxTotalSupply;
    }

    function getReleaseSoundInfo( uint256 id ) public view returns ( SoundInfo memory info ) {
        return _releaseSoundInfo[id];
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return _releaseSoundInfo[id].BaseURI;//_uri;
    }
    function setSoundURI( uint256 id, string memory uriSound ) public onlyOwner {
        _releaseSoundInfo[id].BaseURI = uriSound;
        emit URI( uriSound, id );
    }
    function setPrice( uint256 price ) public onlyOwner { _base_price = price; }
    function getPrice() public view returns(uint256) { return _base_price; }

    // role profit...
    function addRoleProfit( address roles, uint96 profits ) public onlyOwner {
        _addRoleProfit( roles, profits );
    }

    function addBatchRoleProfit( address[] calldata roles, uint96[] calldata profits ) public onlyOwner {
        _addBatchRoleProfit( roles, profits );
        
    }
    function updateRoleProfit( address who, uint96 fee ) public onlyOwner{
        _updateRoleProfit( who, fee );
    }

    function removeRoleProfit( address who ) public onlyOwner{
        _removeRoleProfit( who );
    }

    //copyright.....
    //array must sort, became will get copyright id => search is (small->big) value... 
    function setBatchCopyright( string[] calldata uri_docs, uint256[] calldata amounts ) public onlyOwner {
        require( uri_docs.length == amounts.length , "Copyright : array is error!!" );
        _registerBatchDocument( uri_docs );
        uint256 startID = getDocumentStartID();
        for( uint i = 0 ; i < amounts.length ; )
        {
            _copyrightAmount[ uint16(startID + i) ] = amounts[i];
            unchecked{
                i += 1;
            }
        }
    }
    function getUserCopyrightID( address user, uint256 tokenID ) public view returns (uint256) {
        uint256 balance = balanceOf( user, tokenID );
        uint256 startID = getDocumentStartID();
        uint16 lastID = 0;
        for( uint i = 0 ; i < getDocumentTotalSupply() ; )
        {
            uint16 id = uint16( startID + i );
            if( balance > _copyrightAmount[ id ] ){
                lastID = id;
            }else{
                break;
            }

            unchecked{
                i += 1;
            }
        }

        return lastID;
    }

    function addCopyrightAmount( string calldata uri_doc, uint256 amount ) public onlyOwner {
        uint16 docID = _registerDocument( uri_doc );
        _copyrightAmount[ docID ] = amount;
    }
    function setCopyrightAmount( uint256 docID, uint256 amount ) public onlyOwner {
        require( docID <= type( uint16 ).max, "Copyright : id error!!" );
        _copyrightAmount[ uint16(docID) ] = amount;
    }
    function getCopyrightAmount( uint256 docID ) public view returns (uint256) {
        return _copyrightAmount[ uint16(docID) ];
    }

    // 創作者 發行 單曲, amount 張
    function createSound( uint256 releaseSupply, uint256 onceMax, string memory uriSound ) public onlyOwner {

        uint256 id = _total_supply + getStartID();
        require( releaseSupply <= type( uint256 ).max, "createSound : release Supply is over" );
        require( onceMax <= type( uint256 ).max, "createSound : once is over" );

        _releaseSoundInfo[ id ] = SoundInfo( releaseSupply, 0, onceMax, uriSound );
        unchecked{
            _total_supply += 1;
        }

        emit CreateSound( msg.sender, id, uriSound );
    }

    // fan buy license
    function mintSound( uint256 id, uint256 amount ) public payable {

        uint256 price;
        SoundInfo storage sound = _releaseSoundInfo[id];
        require( amount <= sound.OnceMax, "mintSound : amount too much" );
        require( ( sound.ReleaseCounter + amount ) <= sound.ReleaseSupply, "mintSound : sale out or amount too much" );

        price = amount * _base_price;
        require( msg.value >= price, "mintSound Copyright: wrong price" );

        sound.ReleaseCounter += amount;
        _mint( msg.sender, id, amount, "" );
    }

    function getAddressCopyRight( address user, uint256 tokenID ) public view returns ( uint256 ) {
        return _userCopyright[user][tokenID];
    }

    function withdraw() public payable onlyOwner nonReentrant{

        uint256 balance = address(this).balance;
        uint256 role_amount = 0;
        
        //分潤成員..
        ( uint256 totalAmount, address[] memory role, uint256[] memory amount ) = royalty( balance );
        for( uint256 i = 0 ; i < role.length ; )
        {
            (bool sent, ) = payable(role[i]).call{value: amount[i]}("");
            require(sent, "Failed to send Ether");
            unchecked{
                i += 1;
            }
        }
        role_amount = totalAmount;
        
        uint256 remain = balance - role_amount;//分剩的...
        if( remain > 0 ){
            (bool sent, ) = payable( owner() ).call{value: remain}("");
            require(sent, "Failed to send Ether");
        }
    }

    function getStartID() public pure returns (uint256) { return 1; }

    function supportsInterface(bytes4 _interfaceId) public pure virtual override(ERC1155, ERC5289Library) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

}
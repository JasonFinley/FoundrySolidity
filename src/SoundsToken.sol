// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./RoleProfit.sol";
import "./ERC5289Library.sol";

contract SoundsToken is ERC1155, ReentrancyGuard, Ownable {

    uint256 public _sounds_supply = 0;
    uint256 private _base_price = 0.01 ether;
    string public _name;
    string public _symbol;

    // id => batch supply
    mapping( uint256 => uint256 ) private _batch_total_supply;
    mapping( uint256 => uint256 ) private _batch_counter;
    // id => sound uri
    mapping( uint256 => string ) private _sound_uri;
    // id => copyright price
    mapping( uint16 => uint256 ) private _copyright_price;
    // Role Profit
    RoleProfit private _role_profit;
    // copyright
    ERC5289Library private _copyright;

    constructor( string memory name, string memory symbol, address initOwner ) Ownable( initOwner ) ERC1155("") {
        _name = name;
        _symbol = symbol;
        _copyright = new ERC5289Library();
    }

    function getRoleProfitContract() public view returns ( address ) { return address(_role_profit); }
    function getCopyrightContract() public view returns ( address ) { return address(_copyright); }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return _sound_uri[id];//_uri;
    }
    function setSoundURI( uint256 id, string memory uri_sound ) public onlyOwner {
        _sound_uri[id] = uri_sound;
    }
    function setBasePrice( uint256 price ) public onlyOwner { _base_price = price; }
    function getBasePrice() public view returns(uint256) { return _base_price; }

    // role profit...
    function setRoleProfit( address[] calldata roles, uint96[] calldata profits ) public onlyOwner {
        if( address(_role_profit) == address(0) ){
            _role_profit = new RoleProfit( msg.sender );
        }else{
            _role_profit.addRoleListProfit( roles, profits );
        }
    }

    function addCopyright( string memory uri_doc, uint256 price ) public onlyOwner {
        uint16 docID = _copyright.registerDocument( uri_doc );
        _copyright_price[ docID ] = price;
    }

    // 創作者 發行 單曲, amount 張
    function createSound( uint256 amount, string memory uri_sound ) public onlyOwner {

        uint256 id = _sounds_supply + getStartID();
        _mint( msg.sender, id, amount, "" );
        _sound_uri[id] = uri_sound;
        _batch_total_supply[id] = amount;
        unchecked{
            _sounds_supply += 1;
        }
    }

    // fan buy license
    function mintSound( uint256 id, uint256 licenseID ) public payable {

        
        require( ++_batch_counter[id] <= _batch_total_supply[ id ], "mintSound : sale out" );

        uint16 docID = uint16(licenseID);
        if( docID < _copyright.getTotalSupplyDocument() ){
            require( msg.value >= _copyright_price[ docID ], "mintSound Copyright: wrong price" );
        }else{
            require( msg.value >= _base_price, "mintSound : wrong price" );
        }

        //deposit this contract....不然user有機會gas 花太多, 會降低mint 意願
        //由owner( 創作者自己withdraw )
        bool sent = payable( address(this) ).send(msg.value);
        require(sent, "Failed to send Ether");

        uint256[] memory ids = new uint[](1);
        uint256[] memory amount = new uint[](1);

        ids[0] = id;
        amount[0] = 1;

        _mintBatch( msg.sender, ids, amount, "" );
    }

    function withdraw() public payable onlyOwner nonReentrant{

        uint256 balance = address(this).balance;
        uint256 role_amount = 0;
        
        if( address(_role_profit) != address(0) ){
            //分潤成員..
            ( uint256 totalAmount, address[] memory role, uint256[] memory amount ) = _role_profit.royaltyInfo( balance );
            for( uint256 i = 0 ; i < role.length ; )
            {
                (bool sent, ) = payable(role[i]).call{value: amount[i]}("");
                require(sent, "Failed to send Ether");
                unchecked{
                    i += 1;
                }
            }
            role_amount = totalAmount;
        }

        uint256 remain = balance - role_amount;//分剩的...
        if( remain > 0 ){
            (bool sent, ) = payable( owner() ).call{value: remain}("");
            require(sent, "Failed to send Ether");
        }
    }

    function getStartID() public pure returns (uint256) { return 1; }
}
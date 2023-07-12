// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SoundsToken.sol";

contract SoundsFactory is Ownable {

    struct CreaterInfo {
        uint256 count;
        uint256[] ids;
    }

    struct ContractInfo {
        address addr;
        address creater;
    }

    uint256 public constant _price = 0.1 ether;
    uint256 private _total_supply = 0;
    string public constant _factoryName = "Sounds Factory";

    // id => contract Address & Creater;
    mapping( uint256 => ContractInfo ) private _soundsContractInfo;
    // contract address => id;
    mapping( address => uint256 ) private _soundsAddressToId;
    // creater => creater balanceOf
    mapping( address => CreaterInfo ) private _createrContract;

    event CreateSoundContract( address indexed creater, uint256 indexed id, address indexed contractAddr );

    constructor() Ownable(msg.sender) {}

    function createSoundsContract( 
        string memory name, 
        string memory symbol
    ) public payable {

        require( bytes( name ).length > 0, "createSoundsContract : Contract Name can't empty !!" );
        require( bytes( symbol ).length > 0, "createSoundsContract : Contract symbol can't empty !!" );
        require( msg.value >= _price , "createSoundsContract : pay me 0.1 ether !!" );

        (bool success, ) = payable( owner() ).call{value: msg.value}("");
        require(success, "createSoundsContract : Failed to send Ether");

        SoundsToken sounds = new SoundsToken( name, symbol, msg.sender );

        address soundsAddr = address(sounds);
        uint256 id = _total_supply + getStartID();
        
        _soundsContractInfo[ id ] = ContractInfo( { addr : soundsAddr, creater : msg.sender } );
        _soundsAddressToId[ soundsAddr ] = id;
        CreaterInfo storage myInfo = _createrContract[ msg.sender ];
        myInfo.ids.push( id );
        unchecked{
            myInfo.count += 1;
            _total_supply += 1;
        }

        emit CreateSoundContract( msg.sender, id, soundsAddr );
    }

    function getIDsCreaterOf( address creater ) public view returns ( uint256 cnt, uint256[] memory ids ){
        CreaterInfo storage myInfo = _createrContract[ creater ];
        return ( myInfo.count, myInfo.ids );
    }

    function getCreater( uint256 id ) public view returns ( address contractAddr, address creater ){
        require( id != 0, "getCreater : id zero !!" );
        require( id <= _total_supply, "getCreater : id over total_supply !!" );
        return ( _soundsContractInfo[id].addr, _soundsContractInfo[id].creater );
    }

    function checkContractCreaterSameOwner( address addr ) public view returns ( bool ){
        address tmpContractOwner = Ownable( addr ).owner();
        uint256 id = getIdContractOf(addr);
        ( , address creater ) = getCreater( id );
        return ( tmpContractOwner == creater );
    }

    function getIdContractOf( address addr ) public view returns ( uint256 ){ return _soundsAddressToId[ addr ]; }
    function getStartID() public pure returns ( uint256 ){ return 1; }
    function totalSupply() public view returns ( uint256 ){ return _total_supply; }

}
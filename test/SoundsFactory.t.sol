// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/SoundsFactory.sol";
import "../src/SoundsToken.sol";

contract SoundsFactoryTest is Test {

    address _AdminRole = address( 0x000A );
    address _Singer = address( 0x000B );
    address _Composer = address( 0x000C );
    address _Lyricist = address( 0x000D );
    address _Arranfer = address( 0x000E );
    address _Studio = address( 0x000F );
    address _Fans = address( 0x00AA );
    address _Other = address( 0x00AB );

    uint256 _SingerRoleFee = 5000;
    uint256 _ComposerRoleFee = 2000;
    uint256 _LyricistRoleFee = 1000;
    uint256 _ArranferRoleFee = 500;
    uint256 _StudioRoleFee = 500;
    uint256 _FansRoleFee = 100;
    uint256 _OtherRoleFee = 50;

    SoundsFactory _sounds_factory;

    function setUp() public {
        vm.startPrank( _AdminRole );
        _sounds_factory = new SoundsFactory();
        vm.stopPrank();
    }

    function testGetSoundsTokenInformation() public {
        string memory tokenName = "My Song Contract";
        string memory tokenSymbol = "MSC";
        vm.startPrank( _Singer );
        vm.deal( _Singer, 1 ether);
        _sounds_factory.createSoundsToken{ value: 0.1 ether }( tokenName, tokenSymbol );
        vm.stopPrank();
        ( , uint256[] memory ids ) = _sounds_factory.getIDsCreaterOf( _Singer );
        ( address contractAddr, ) = _sounds_factory.getCreater( ids[0] );

        ( string memory name,
        string memory symbol,
        uint256 supply ) = _sounds_factory.getSoundsTokenInformation( contractAddr );
        assertEq( name, tokenName );
        assertEq( symbol, tokenSymbol );
        assertEq( supply, 0 );
    }

    function testCreateSoundsContract() public {
        string memory tokenName = "My Song Contract";
        string memory tokenSymbol = "MSC";
        vm.startPrank( _Singer );
        vm.deal( _Singer, 1 ether);
        _sounds_factory.createSoundsToken{ value: 0.1 ether }( tokenName, tokenSymbol );
        vm.stopPrank();

        assertEq( _sounds_factory.totalSupply(), 1 );
        assertEq( _Singer.balance, 0.9 ether );
        assertEq( _AdminRole.balance, 0.1 ether );
    }

    function testGetIDsCreaterOf() public {
        testCreateSoundsContract();
        
        ( uint256 cnt, uint256[] memory ids ) = _sounds_factory.getIDsCreaterOf( _Singer );
        assertEq( cnt, 1 );
        for( uint i = 0 ; i < cnt ; i++ )
        {
            ( address contractAddr, address creater ) = _sounds_factory.getCreater( ids[i] );
            assertEq( creater, _Singer );
            assertFalse( contractAddr == address(0) );
            assertFalse( !_sounds_factory.isContractCreaterSameOwner( contractAddr ) );
            assertEq( _sounds_factory.getIdContractOf( contractAddr ), ids[i] );
        }
    }
}

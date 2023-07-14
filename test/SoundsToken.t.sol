// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/RoleProfit.sol";
import "../src/SoundsFactory.sol";

contract SoundsTokenTest is Test {

    address _AdminRole = address( 0x000A );
    address _Singer = address( 0x000B );
    address _Composer = address( 0x000C );
    address _Lyricist = address( 0x000D );
    address _Arranfer = address( 0x000E );
    address _Studio = address( 0x000F );
    address _Fans = address( 0x00AA );
    address _Other = address( 0x00AB );

    uint96 _SingerRoleFee = 5000;
    uint96 _ComposerRoleFee = 2000;
    uint96 _LyricistRoleFee = 1000;
    uint96 _ArranferRoleFee = 500;
    uint96 _StudioRoleFee = 500;
    uint96 _FansRoleFee = 100;
    uint96 _OtherRoleFee = 50;

    SoundsFactory _soundsFactory;
    SoundsToken _soundsToken;
    string _tokenName = "My Sounds Contract";
    string _tokenSymbol = "MSC";
    address _tokenAddress;
    string _soundsURI = "ipfs://12345678900987654321";
    string[3] _copyright = ["ipfs://NovicePlayer", "ipfs://MasterPlayer", "ipfs://ProfessionalPlayer"];
    uint256[3] _copyrightAmount = [ 10000, 40000, 200000 ];

    function setUp() public {
        vm.startPrank( _AdminRole );
        _soundsFactory = new SoundsFactory();
        vm.stopPrank();

        vm.deal( _Singer, 1 ether );
        vm.deal( _Studio, 1 ether );
        vm.deal( _Fans, 1 ether );
        vm.deal( _Other, 1 ether );

        vm.startPrank( _Singer );
        (address addr, ) = _soundsFactory.createSoundsContract{value: 0.1 ether}( _tokenName, _tokenSymbol );
        _tokenAddress = addr;
        vm.stopPrank();
        
    }

    function testSoundsContractInformation() public {
        _soundsToken = SoundsToken( _tokenAddress );
        assertEq( _soundsToken._name(), _tokenName );
        assertEq( _soundsToken._symbol(), _tokenSymbol );
        assertEq( _soundsToken._total_supply(), 0 );
        assertEq( _soundsToken.owner(), _Singer );
    }

    function testCreateSound() public {
        _soundsToken = SoundsToken( _tokenAddress );
        vm.startPrank( _Singer );
        _soundsToken.createSound( 100000000, 10000, _soundsURI );
        vm.stopPrank();
        assertEq( _soundsToken._total_supply(), 1 );
        assertEq( _soundsToken.uri(1), _soundsURI );
    }

    function testMintSound() public {
        _soundsToken = SoundsToken( _tokenAddress );
        vm.startPrank( _Singer );
        _soundsToken.createSound( 100000000, 10000, _soundsURI );
        vm.stopPrank();

        vm.startPrank( _Fans );
        uint256 cast = _soundsToken.getPrice();
        uint256 amount = 10000;
        _soundsToken.mintSound{value: amount * cast }( 1, amount );
        vm.stopPrank();

        assertEq( _soundsToken.balanceOf( _Fans, 1 ), amount );
        assertEq( address(_soundsToken).balance, amount * cast );
        assertEq( _Fans.balance, (1 ether - (amount * cast)) );
    }

    function testMintSoundCopyRight() public {
        _soundsToken = SoundsToken( _tokenAddress );
        vm.startPrank( _Singer );
        _soundsToken.createSound( 100000000, 50000, _soundsURI );
        string[] memory cp = new string[](3);
        uint256[] memory cpamount = new uint256[](3);
        for( uint i = 0 ; i < 3 ; i++ )
        {
            cp[i] = _copyright[i];
            cpamount[i] = _copyrightAmount[i];
        }
        _soundsToken.setBatchCopyright( cp, cpamount );
        vm.stopPrank();
        uint256 docCnt = _soundsToken.getDocumentTotalSupply();
        assertEq( docCnt, _copyright.length );
        for( uint i = 0 ; i < docCnt ; i++ )
        {
            uint16 docID = uint16(_soundsToken.getDocumentStartID() + i);
            assertEq( _soundsToken.getCopyrightAmount(docID), _copyrightAmount[i]  );
        }

        vm.startPrank( _Fans );
        uint256 cost = _soundsToken.getPrice();
        uint256 amount = 20000;
        _soundsToken.mintSound{value: amount * cost }( 1, amount );
        vm.stopPrank();
        uint256 userDocID = _soundsToken.getUserCopyrightID( _Fans, 1 );
        assertEq( userDocID, 1 );
        assertEq( _soundsToken.legalDocument( uint16(userDocID) ), _copyright[0] );
    }

    function testMintSoundCopyRightRoleProFit() public {
        _soundsToken = SoundsToken( _tokenAddress );
        vm.startPrank( _Singer );
        _soundsToken.createSound( 100000000, 50000, _soundsURI );
        string[] memory cp = new string[](3);
        uint256[] memory cpamount = new uint256[](3);
        for( uint i = 0 ; i < 3 ; i++ )
        {
            cp[i] = _copyright[i];
            cpamount[i] = _copyrightAmount[i];
        }
        _soundsToken.setBatchCopyright( cp, cpamount );
        address[] memory roles = new address[](4);
        uint96[] memory profits = new uint96[](4);
        roles[0] = _Singer;
        roles[1] = _Composer;
        roles[2] = _Lyricist;
        roles[3] = _Arranfer;
        profits[0] = _SingerRoleFee;
        profits[1] = _ComposerRoleFee;
        profits[2] = _LyricistRoleFee;
        profits[3] = _ArranferRoleFee;
        _soundsToken.addBatchRoleProfit( roles, profits );
        vm.stopPrank();

        vm.startPrank( _Fans );
        uint256 cost = _soundsToken.getPrice();
        uint256 amount = 20000;
        _soundsToken.mintSound{value: amount * cost }( 1, amount );
        vm.stopPrank();
        console.log( " $$$ withdraw $$$ before" );
        console.log( address(_soundsToken).balance );
        console.log( _Singer.balance );
        console.log( _Composer.balance );
        console.log( _Lyricist.balance );
        console.log( _Arranfer.balance );

        vm.startPrank( _Singer );
        _soundsToken.withdraw();
        vm.stopPrank();

        console.log( " $$$ withdraw $$$ after" );
        console.log( address(_soundsToken).balance );
        console.log( _Singer.balance );
        console.log( _Composer.balance );
        console.log( _Lyricist.balance );
        console.log( _Arranfer.balance );
        uint256 maxValue = amount * cost;
        uint256 compValue = maxValue * _ComposerRoleFee / 10000;
        uint256 lyriValue = maxValue * _LyricistRoleFee / 10000;
        uint256 arraValue = maxValue * _ArranferRoleFee / 10000;
        uint256 curValue = compValue + lyriValue + arraValue;
        assertEq( _Composer.balance, compValue );
        assertEq( _Lyricist.balance, lyriValue );
        assertEq( _Arranfer.balance, arraValue );
        uint256 singValue = 1 ether - 0.1 ether + maxValue - curValue;
        assertEq( _Singer.balance, singValue );
    }

}

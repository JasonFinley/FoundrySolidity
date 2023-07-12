// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/RoleProfit.sol";

contract RoleProfitTest is Test {

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

    RoleProfit _roleprofit;

    function setUp() public {
        vm.startPrank( _AdminRole );
        //_roleprofit = new RoleProfit( _AdminRole );
        vm.stopPrank();
    }

    function testAddRoleProfit() public {
        vm.startPrank( _AdminRole );
        _roleprofit = new RoleProfit( _AdminRole );
        _roleprofit.addRoleProfit( _Singer, uint96(_SingerRoleFee) );
        vm.stopPrank();

        uint256 fee = _roleprofit.getRoleProfitFee( _Singer );
        assertEq( fee, _SingerRoleFee );
    }

    function testAddRoleListProfit() public {
        address[] memory user_wallet = new address[](4);
        uint96[] memory user_fee = new uint96[](4);
        user_wallet[0] = _Singer;
        user_wallet[1] = _Composer;
        user_wallet[2] =  _Lyricist;
        user_wallet[3] = _Arranfer;
        user_fee[0] = uint96(_SingerRoleFee);
        user_fee[1] = uint96(_ComposerRoleFee);
        user_fee[2] = uint96(_LyricistRoleFee);
        user_fee[3] = uint96(_ArranferRoleFee);

        vm.startPrank( _AdminRole );
        _roleprofit = new RoleProfit( _AdminRole );
        _roleprofit.addRoleListProfit( user_wallet, user_fee );
        vm.stopPrank();

        for( uint i = 0 ; i < 4 ; i++ )
        {
            uint256 fee = _roleprofit.getRoleProfitFee( user_wallet[i] );
            assertEq( fee, user_fee[i] );
        }

        ( uint256 count, RoleProfit.RoleProfitFee[] memory profit ) = _roleprofit.getRoleProfit();
        bool isSame = false;
        for( uint i = 0 ; i < count ; i++ )
        {
            isSame = false;
            for( uint j = 0 ; j < user_wallet.length ; j++ )
            {
                if( profit[i].role == user_wallet[j] && profit[i].fee == user_fee[j] ){
                    isSame = true;
                    break;
                }
            }
            assertFalse( !isSame );
        }
    }

    function testRoyaltyInfo() public {
        address[] memory user_wallet = new address[](4);
        uint96[] memory user_fee = new uint96[](4);
        user_wallet[0] = _Singer;
        user_wallet[1] = _Composer;
        user_wallet[2] =  _Lyricist;
        user_wallet[3] = _Arranfer;
        user_fee[0] = uint96(_SingerRoleFee);
        user_fee[1] = uint96(_ComposerRoleFee);
        user_fee[2] = uint96(_LyricistRoleFee);
        user_fee[3] = uint96(_ArranferRoleFee);
        uint256 salePrice = 0.1 ether;

        vm.startPrank( _AdminRole );
        _roleprofit = new RoleProfit( _AdminRole );
        _roleprofit.addRoleListProfit( user_wallet, user_fee );
        vm.stopPrank();
        (uint256 totalAmount, address[] memory role, uint256[] memory amount) = _roleprofit.royaltyInfo( salePrice );

        uint256 tmp_fee = 0;
        for( uint i = 0 ; i < user_fee.length ; i++ )
        {
            tmp_fee += user_fee[i];
        }

        uint256 tmp_amount = salePrice * tmp_fee / 10000;
        assertEq( totalAmount, tmp_amount );

        tmp_amount = 0;
        for( uint i = 0 ; i < amount.length ; i++ )
        {
            tmp_amount += amount[i];
        }
        assertEq( totalAmount, tmp_amount );

        for( uint i = 0 ; i < role.length ; i++ )
        {
            uint256 fee = _roleprofit.getRoleProfitFee( role[i] );
            tmp_amount = salePrice * fee / 10000;
            assertEq( amount[i], tmp_amount );
        }
        
    }

}

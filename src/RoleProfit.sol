// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IRoleProfit.sol";
//ERC2981 //Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information

//設定分潤的合約
contract RoleProfit is IRoleProfit {

    RoleProfitFee[] private _role_profit;

    constructor() {}

    function royalty( uint256 supply ) public view returns (uint256 totalAmount, address[] memory role, uint256[] memory amount) {
        uint256 total_amount = 0;
        uint256 feeDen = _feeDenominator();
        uint256 cnt = _role_profit.length;
        address[] memory roleList = new address[](cnt);
        uint256[] memory amountList = new uint256[](cnt);

        for( uint256 i = 0 ; i < cnt ; )
        {
            RoleProfitFee storage roleProfit = _role_profit[i];
            require( roleProfit.role != address(0), "role profit is zero" );

            uint256 tmp_amount = (supply * roleProfit.fee) / feeDen;
            roleList[i] = roleProfit.role;
            amountList[i] = tmp_amount;
            total_amount += tmp_amount;

            unchecked{
                i += 1;
            }
        }

        return ( total_amount, roleList, amountList );
    }

    function roleProfitFeeBalanceOf( address who ) public view returns( uint96 ){
        require( who != address(0), "address is zero" );
        for( uint256 i = 0 ; i < _role_profit.length ; )
        {
            if( _role_profit[i].role == who ){
                return _role_profit[i].fee;
            }
            unchecked{
                i += 1;
            }
        }
        return 0;
    }

    function roleProfitAll() public view returns ( RoleProfitFee[] memory roleProfit ) {
        return _role_profit;
    }

    function isOverFeeDenominator() public view returns (bool) {
        uint256 i;
        uint256 total_fee = 0;
        uint256 feeDen = _feeDenominator();
        for( i = 0 ; i < _role_profit.length ; )
        {
            total_fee += _role_profit[i].fee;
            if( total_fee > feeDen )
                return true;
            unchecked{
                i += 1;
            }
        }
        return false;
    }

    function _feeDenominator() internal pure returns (uint96){
        return 10000;
    }

    function _addBatchRoleProfit( address[] calldata who, uint96[] calldata fee ) internal {
        require( who.length == fee.length, "role & fee length are different!!" );
        uint256 total_fee = 0;
        uint256 feeDen = _feeDenominator();
        for( uint i = 0 ; i < who.length ; )
        {
            require( who[i] != address(0), "address is zero" );
            _role_profit.push( RoleProfitFee( who[i], fee[i] ) );
            total_fee += fee[i];
            require( total_fee <= feeDen , "Profit Total Fee over 10000" );
            emit AddRoleFit( who[i], fee[i] );
            unchecked{
                i += 1;
            }
        }

    }

    function _addRoleProfit( address who, uint96 fee ) internal {
        require( who != address(0), "address is zero" );
        _role_profit.push( RoleProfitFee( who, fee ) );
        emit AddRoleFit( who, fee );
        require( !isOverFeeDenominator(), "check Profit Total Fee over 10000" );
    }

    function _updateRoleProfit( address who, uint96 fee ) internal {
        require( who != address(0), "address is zero" );
        for( uint256 i = 0 ; i < _role_profit.length ; )
        {
            if( _role_profit[i].role == who ){
                _role_profit[i].fee = fee;
                break;
            }
            unchecked{
                i += 1;
            }
        }

        require( !isOverFeeDenominator(), "Profit Total Fee over 10000" );
    }

    function _removeRoleAllProfit() internal {
        delete _role_profit;
        emit RemoveRoleFit( address(0), "Remove ALL Role" );
    }

    function _removeRoleProfit( address who ) internal {
        require( who != address(0), "address is zero" );
        uint256 i = 0;
        uint256 cnt = _role_profit.length;
        for( i = 0 ; i < cnt ;  )
        {
            if( _role_profit[i].role == who ){
                _role_profit[i] = _role_profit[ cnt - 1 ];
                _role_profit.pop();
                emit RemoveRoleFit( who, "Remove" );
                return;
            }

            unchecked{
                i += 1;
            }
        }
    }
}

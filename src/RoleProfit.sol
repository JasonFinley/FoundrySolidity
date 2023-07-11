// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
//ERC2981 //Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information

//設定分潤的合約
contract RoleProfit is Ownable {

    // 分潤比例 : max 10000 => 0.01 * 10000 %
    struct RoleProfitFee {
        address role;
        uint96 fee;
    }

    RoleProfitFee[] private _role_profit;

    constructor( address initOwner ) Ownable( initOwner ) {}

    function royaltyInfo( uint256 salePrice) public view returns (uint256 totalAmount, address[] memory role, uint256[] memory amount) {
        uint256 total_amount = 0;
        uint256 feeDen = _feeDenominator();
        uint256 cnt = _role_profit.length;
        address[] memory roleList = new address[](cnt);
        uint256[] memory amountList = new uint256[](cnt);

        for( uint256 i = 0 ; i < cnt ; )
        {
            RoleProfitFee storage roleProfit = _role_profit[i];
            require( roleProfit.role != address(0), "role profit is zero" );

            uint256 tmp_amount = (salePrice * roleProfit.fee) / feeDen;
            roleList[i] = roleProfit.role;
            amountList[i] = tmp_amount;
            total_amount += tmp_amount;

            unchecked{
                i += 1;
            }
        }

        return ( total_amount, roleList, amountList );
    }

    function getRoleProfitFee( address wallet ) public view returns( uint96 ){
        require( wallet != address(0), "address is zero" );
        for( uint256 i = 0 ; i < _role_profit.length ; )
        {
            if( _role_profit[i].role == wallet ){
                return _role_profit[i].fee;
            }
            unchecked{
                i += 1;
            }
        }
        return 0;
    }

    function getRoleProfit() public view returns ( uint256 count, RoleProfitFee[] memory profit ) {
        return ( _role_profit.length, _role_profit );
    }

    function checkProfitTotalFee() public view returns (bool) {
        uint256 i;
        uint256 total_fee = 0;
        uint256 feeDen = _feeDenominator();
        for( i = 0 ; i < _role_profit.length ; )
        {
            total_fee += _role_profit[i].fee;
            if( total_fee > feeDen )
                return false;
            unchecked{
                i += 1;
            }
        }
        return true;
    }

    function _feeDenominator() internal pure returns (uint96){
        return 10000;
    }

    function addRoleListProfit( address[] calldata wallet, uint96[] calldata fee ) public onlyOwner{
        require( wallet.length == fee.length, "role & fee length are different!!" );
        uint256 total_fee = 0;
        uint256 feeDen = _feeDenominator();
        for( uint i = 0 ; i < wallet.length ; )
        {
            require( wallet[i] != address(0), "address is zero" );
            _role_profit.push( RoleProfitFee( wallet[i], fee[i] ) );
            total_fee += fee[i];
            require( total_fee > feeDen , "Profit Total Fee over 10000" );
        }

    }

    function addRoleProfit( address wallet, uint96 fee ) public onlyOwner{
        require( wallet != address(0), "address is zero" );
        _role_profit.push( RoleProfitFee( wallet, fee ) );

        require( checkProfitTotalFee(), "Profit Total Fee over 10000" );
    }

    function updateRoleProfit( address wallet, uint96 fee ) public onlyOwner{
        require( wallet != address(0), "address is zero" );
        for( uint256 i = 0 ; i < _role_profit.length ; )
        {
            if( _role_profit[i].role == wallet ){
                _role_profit[i].fee = fee;
                break;
            }
            unchecked{
                i += 1;
            }
        }

        require( checkProfitTotalFee(), "Profit Total Fee over 10000" );
    }

    function removeRoleAllProfit() public onlyOwner{
        delete _role_profit;
    }

    function removeRoleProfit( address wallet ) public onlyOwner{
        require( wallet != address(0), "address is zero" );
        uint256 i = 0;
        uint256 cnt = _role_profit.length;
        for( i = 0 ; i < cnt ;  )
        {
            if( _role_profit[i].role == wallet ){
                _role_profit[i] = _role_profit[ cnt - 1 ];
                _role_profit.pop();
                return;
            }

            unchecked{
                i += 1;
            }
        }
    }
}

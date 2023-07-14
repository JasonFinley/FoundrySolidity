/// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IRoleProfit {

    // 分潤比例 : max 10000 => 0.01 * 10000 %
    struct RoleProfitFee {
        address role;
        uint96 fee;
    }
    
    event AddRoleFit(address indexed who, uint96 indexed fee);
    event RemoveRoleFit(address indexed who, string message);

    function royalty( uint256 supply ) external view returns (uint256 totalAmount, address[] memory role, uint256[] memory amount);

    function roleProfitFeeBalanceOf( address who ) external view returns( uint96 );

    function roleProfitAll() external view returns ( RoleProfitFee[] memory roleProfit );

    function isOverFeeDenominator() external view returns (bool);
}
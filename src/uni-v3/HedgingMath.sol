// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "./interfaces/Interfaces.sol";
import {UD60x18, ud, unwrap} from "@prb/math/UD60x18.sol";
import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";

contract HedgingMath {

        function get_liquidity_xy(uint160 sp, uint160 sa, uint160 sb, uint Value) public pure returns (uint256 x,uint256 y)  { //find_max_x
        // FullMath.mul()
        // uint256 numerator1=uint256(sp-sa);
        // uint256 numerator2=uint256(sp-sa);
        // uint256 numerator1 = uint256(Value) << FixedPoint96.RESOLUTION;
        uint256 numerator1 = uint256(Value) << 96;
        uint256 dividorFirst = FullMath.mulDiv(uint256(sp - sa), uint256(sb), uint256(sb - sp));
        uint256 dividorSecond = FullMath.mulDiv(numerator1, 1<<96, (dividorFirst + sp)) / sp;
        x = dividorSecond;
        y = Value - FullMath.mulDiv(uint256(sp), uint256(sp), 2**96) * x / 2**96;
        return (x, y);
        // return x = Value*2**96/((sp-sa)*sp*sb/(sb-sp)+sp*sp);
    }

    function findMaxX2(uint p, uint a, uint b, uint vMax) public pure returns (uint) {
        UD60x18 sp = ud(p).sqrt();
        UD60x18 sa = ud(a).sqrt();
        UD60x18 sb = ud(b).sqrt();
        UD60x18 x2 = ud(vMax).div(
            (sp - sa).mul(sp * sb).div((sb - sp)) + ud(p)
        );
        return unwrap(x2);
    }

    function calculateAmounts(uint p, uint a, uint b, uint x, uint y, uint P1) public view returns (uint, uint) {
        UD60x18 sp = ud(p).sqrt();
        UD60x18 sa = ud(a).sqrt();
        UD60x18 sb = ud(b).sqrt();  
        
    }


    function findEqualPnLValues(uint p, uint a, uint b, uint P1, uint shortPrice, uint maxValue) external view returns (uint, uint) {
        uint virtualLP = 1000e18;
        uint x = findMaxX2(p, a, b, virtualLP);
        uint y = virtualLP - unwrap(ud(x).mul(ud(p)));



        // (uint x1)

    }

    function getLiquidity0(UD60x18 x, UD60x18 sa, UD60x18 sb) public pure returns (UD60x18) {
        return x.mul(sa).mul(sb).div(sb - sa);
    }

    function getLiquidity1(UD60x18 y, UD60x18 sa, UD60x18 sb) public pure returns (UD60x18) {
        return y.div(sa).div(sb - sa);
    }
/*
def get_liquidity_0(x, sa, sb):
    return x * sa * sb / (sb - sa)

def get_liquidity_1(y, sa, sb):
    return y / (sb - sa)

def get_liquidity(x, y, sp, sa, sb):
    if sp <= sa:
        liquidity = get_liquidity_0(x, sa, sb)
    elif sp < sb:
        liquidity0 = get_liquidity_0(x, sp, sb)
        liquidity1 = get_liquidity_1(y, sa, sp)
        liquidity = min(liquidity0, liquidity1)
    else:
        liquidity = get_liquidity_1(y, sa, sb)
    return liquidity
*/

    /**
    def calculateAmounts(p, a, b, x, y, P1):
        sp = p ** 0.5
        sa = a ** 0.5
        sb = b ** 0.5
        L = get_liquidity(x, y, sp, sa, sb)

        sp1 = P1 ** 0.5

        sp = max(min(sp, sb), sa)
        sp1 = max(min(sp1, sb), sa)

        delta_p = sp1 - sp
        delta_inv_p = 1/sp1 - 1/sp
        delta_x = delta_inv_p * L
        delta_y = delta_p * L
        x1 = x + delta_x
        y1 = y + delta_y
        
        return x1, y1



     */

    /*

# KZ: find_equal_pnl_values using brute force method, could cost a large gas fee. and find_equal_pnl_values2 has the same solution, with less calculation cost
# KZ: Moreover, the find_equal_pnl_values2 has better accuracy
def find_equal_pnl_values2(p, a, b, P1, short_price, maximumValue):
    # Calculate PNL_V3
    Virturl_LP=1000 

    x = find_max_x2(p, a, b, Virturl_LP)  # KZ: what's x at p
    y = Virturl_LP - x * p
    x1, y1 = calculateAmounts(p, a, b, x, y, P1)
    value = x * p + y
    value1 = x1 * P1 + y1
    PNL_V3 = value1 - value  # KZ: the calculate imp loss
   
    # Calculate PNL_short position
    Virturl_Short=PNL_V3/(P1-short_price)*short_price
    print("x0 = {:.2f}".format(PNL_V3))
    print("y0 = {:.2f}".format(Virturl_Short))
    
    initial_portfolio_value_v3=Virturl_LP
    initial_portfolio_value_short=Virturl_Short

    return initial_portfolio_value_v3, initial_portfolio_value_short
    
    
     */



}
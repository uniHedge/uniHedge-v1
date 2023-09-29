// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "./interfaces/Interfaces.sol";
import {UD60x18, ud, unwrap} from "@prb/math/UD60x18.sol";
import "./Leverage.sol";
import "./Provider.sol";

import "forge-std/console.sol";

import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "forge-std/console.sol";

contract UniswapV3LPHedger is UniswapV3LiquidityProvider {
    using SafeERC20 for IERC20;

    Leverage leverage;

    constructor(address _leverage) {
        leverage = Leverage(_leverage);
    }

    struct IL_HEDGE {
        uint tokenId;
        uint leverageId;
        uint128 liquidity;
        address token0;
        address token1;
        uint amount0;
        uint amount1;
        uint shortAmount;
    }

    mapping(address => IL_HEDGE) public userPositions;

    // @dev currently for the sake of simplicity for the hackathon atm users can only open 1 hedged LP position at a time
    function openHedgedLP(address token0, address token1, uint amountToken0, uint amountToken1, int24 tickLower, int24 tickUpper) external {
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amountToken0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amountToken1);

        IERC20(token0).safeApprove(address(leverage), type(uint).max);
        IERC20(token1).safeApprove(address(leverage), type(uint).max);

        uint price = leverage.getPrice(token1, token0) * 1e12;  // hardcode usdc => weth
        uint portfolioValue = (price * amountToken1 / 1e18) + amountToken0 * 1e12;

        {
            uint160 p = TickMath.getSqrtRatioAtTick(73655);
            uint160 a = TickMath.getSqrtRatioAtTick(tickLower);
            uint160 b = TickMath.getSqrtRatioAtTick(tickUpper);

            console.log("PRICE");
            console.log(p);
            console.log(a);
            console.log(b);

            uint LP_value = ud(portfolioValue).mul(ud(0.79e18)).unwrap(); 
            uint SHORT_value = (portfolioValue - LP_value) / 1e12; // in base 1e6 i.e. usdc

            (uint x, uint y) = get_liquidity_xy(p, a, b, LP_value);

            console.log("xy");
            console.log(x);
            console.log(y);

            console.log("LP");
            console.log(LP_value);
            console.log(SHORT_value);
        }

        // @dev todo: calculate the amount to supply as LP to uni, and to short
        // (uint tokenId, uint128 liquidity, uint amount0, uint amount1) = mintNewPosition(token0, token1, x, y, tickLower, tickUpper);
        // leverage.short(token0, token1, z, ud(1.25e18));

        (uint tokenId, uint128 liquidity, uint amount0, uint amount1) = mintNewPosition(token0, token1, 6000e6, 4e18, tickLower, tickUpper);
        leverage.short(token0, token1, 3700e6, ud(1.25e18));

        uint leverageId = leverage.getUserIDlength(msg.sender);

        // save user position
        IL_HEDGE memory data = IL_HEDGE(tokenId, leverageId, liquidity, token0, token1, amount0, amount1, 200e6);
        userPositions[msg.sender] = data;
    }

    // @dev currently for the sake of simplicity for the hackathon atm users can only open 1 hedged LP position at a time
    // this will be solved with a simple mapping of address user => array of IDs of positions
    function closeHedgedLP() external {
        userPositions[msg.sender].amount0 = 0;
        userPositions[msg.sender].amount1 = 0;

        (uint amount0, uint amount1) = decreaseLiquidityCurrentRange(userPositions[msg.sender].tokenId, userPositions[msg.sender].liquidity);
        
        uint leverageId = userPositions[msg.sender].leverageId;

        address token0 = userPositions[msg.sender].token0;
        address token1 = userPositions[msg.sender].token1;

        uint bal0_t0 = IERC20(token0).balanceOf(address(this));
        uint bal1_t0 = IERC20(token0).balanceOf(address(this));

        leverage.closePosition(leverageId);

        uint bal0_t1 = IERC20(token0).balanceOf(address(this));
        uint bal1_t1 = IERC20(token0).balanceOf(address(this));

        IERC20(token0).safeTransfer(msg.sender, bal0_t1 - bal0_t0 + amount0);
        IERC20(token1).safeTransfer(msg.sender, bal1_t1 - bal1_t0 + amount1);
    }

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

    function findMaxX2(uint p, uint a, uint b, uint vMax) external pure returns (uint) {
        UD60x18 sp = ud(p).sqrt();
        UD60x18 sa = ud(a).sqrt();
        UD60x18 sb = ud(b).sqrt();
        UD60x18 x2 = ud(vMax).div(
            (sp - sa).mul(sp * sb).div((sb - sp)) + ud(p)
        );
        return unwrap(x2);
    }

    /*
    
    def find_max_x2(p, a, b, vMax): # KZ: find_max_x using brute force method, could cost a large gas fee. and find_max_x2 has the same solution, with less calculation cost
    sp = p ** 0.5
    sa = a ** 0.5
    sb = b ** 0.5
    x2 = vMax / ((sp - sa) * sp * sb / (sb - sp) + p)
    return x2

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

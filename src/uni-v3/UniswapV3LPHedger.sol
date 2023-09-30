// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "./interfaces/Interfaces.sol";
import {UD60x18, ud, unwrap} from "@prb/math/UD60x18.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Leverage.sol";
import "./Provider.sol";
import "./HedgingMath.sol";

import "forge-std/console.sol";

contract UniswapV3LPHedger is UniswapV3LiquidityProvider, HedgingMath {
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


}

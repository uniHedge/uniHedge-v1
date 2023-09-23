// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "./interfaces/Interfaces.sol";
import {UD60x18, ud, unwrap} from "@prb/math/UD60x18.sol";
import "./Leverage.sol";
import "./Provider.sol";

import "forge-std/console.sol";

import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapV3LPHedger is UniswapV3LiquidityProvider, Leverage {
    

    // Leverage leverage;

    constructor(address _leverage, address _pool) Leverage (_pool) {
        // leverage = Leverage(_leverage);
    }


    function openHedgedLP(address token0, address token1, uint amountToken0, uint amountToken1, int24 tickLower, int24 tickUpper) external {

        IERC20(token0).safeTransferFrom(amountToken0);
        IERC20(token1).safeTransferFrom(amountToken1);

        // @dev todo: calculate the amount to supply as LP to uni, and to short
        mintNewPosition(token0, token1, 1e18, 1e18, tickLower, tickUpper); // filler vals`

        short(token0, token1, 1e18, ud(1e18));
    }

}

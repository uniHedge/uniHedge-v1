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

        // @dev todo: calculate the amount to supply as LP to uni, and to short
        (uint tokenId, uint128 liquidity, uint amount0, uint amount1) = mintNewPosition(token0, token1, 400e6, 0.2e18, tickLower, tickUpper);
        
        leverage.short(token0, token1, 200e6, ud(1.25e18));

        uint leverageId = leverage.getUserIDlength(msg.sender);

        // save user position
        IL_HEDGE memory data = IL_HEDGE(tokenId, leverageId, liquidity, token0, token1, amount0, amount1, 200e6);
        userPositions[msg.sender] = data;
    }


    function closeHedgedLP(uint positionId) external {
        userPositions[msg.sender].amount0 = 0;
        userPositions[msg.sender].amount1 = 0;

        (uint amount0, uint amount1) = decreaseLiquidityCurrentRange(userPositions[msg.sender].tokenId, userPositions[msg.sender].liquidity);
        
        uint tokenId = userPositions[msg.sender].tokenId;
        uint leverageId = userPositions[msg.sender].leverageId;

        address token0 = userPositions[msg.sender].token0;
        address token1 = userPositions[msg.sender].token1;

        uint bal0_t0 = IERC20(token0).balanceOf(address(this));
        uint bal1_t0 = IERC20(token0).balanceOf(address(this));

        leverage.closePosition(leverageId);

        uint bal0_t1 = IERC20(token0).balanceOf(address(this));
        uint bal1_t1 = IERC20(token0).balanceOf(address(this));

        IERC20(token0).safeTransfer(msg.sender, bal0_t1 - bal0_t1 + amount0);
        IERC20(token1).safeTransfer(msg.sender, bal1_t1 - bal1_t1 + amount1);
    }

}

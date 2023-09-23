// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../../src/uni-v3/Provider.sol";

import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

contract UniswapV3LiquidityTest is Test {
    int24 private constant MIN_TICK = -887272;
    int24 private constant MAX_TICK = -MIN_TICK;
    int24 private constant TICK_SPACING = 60;

    uint ethFork;
    string ETH_RPC = vm.envString("ETH_RPC");

    address WETH = vm.envAddress("WETH_ETH");
    address DAI = vm.envAddress("DAI_ETH");

    IWETH private weth = IWETH(WETH);
    IERC20 private dai = IERC20(DAI);

    // address private constant DAI_WHALE = 0xe81D6f03028107A20DBc83176DA82aE8099E9C42;

    UniswapV3LiquidityProvider uni;

    function setUp() public {
        ethFork = vm.createSelectFork(ETH_RPC);

        uni = new UniswapV3LiquidityProvider();

        deal(DAI, address(this), 1e18 * 1e6);
        deal(WETH, address(this), 1e18 * 1e6);

        weth.deposit{value: 2 * 1e18}();
        dai.approve(address(uni), type(uint).max);
        weth.approve(address(uni), type(uint).max);

     }

    function testSupplyLiquidityFullRange() public {
        // Track total liquidity
        uint128 liquidity;

        // Mint new position
        uint daiAmount = 10000 * 1e18;
        uint wethAmount = 1e18;
        
        (uint tokenId, 
        uint128 liquidityDelta,
        uint amount0, 
        uint amount1) = uni.mintNewPosition(
            DAI, 
            WETH, 
            daiAmount, 
            wethAmount, 
            (MIN_TICK / TICK_SPACING) * TICK_SPACING,
            (MAX_TICK / TICK_SPACING) * TICK_SPACING);

        console.log("TICKS");
        console.logInt((MIN_TICK / TICK_SPACING) * TICK_SPACING);
        console.logInt((MAX_TICK / TICK_SPACING) * TICK_SPACING);
 
        console.log("in test 2");
        
        liquidity += liquidityDelta;

        console.log("--- Mint new position ---");
        console.log("token id", tokenId);
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);

        // Collect fees
        (uint fee0, uint fee1) = uni.collectAllFees(tokenId);

        console.log("--- Collect fees ---");
        console.log("fee 0", fee0);
        console.log("fee 1", fee1);

        // Increase liquidity
        uint daiAmountToAdd = 5 * 1e18;
        uint wethAmountToAdd = 0.5 * 1e18;

        (liquidityDelta, amount0, amount1) = uni.increaseLiquidityCurrentRange(
            tokenId,
            daiAmountToAdd,
            wethAmountToAdd
        );
        liquidity += liquidityDelta;

        console.log("--- Increase liquidity ---");
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);

        // Decrease liquidity
        (amount0, amount1) = uni.decreaseLiquidityCurrentRange(tokenId, liquidity);
        console.log("--- Decrease liquidity ---");
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);
    }

    function testSupplyLiquidityConcentratedRange() public {
        // Track total liquidity
        uint128 liquidity;

        // Mint new position
        uint daiAmount = 1000 * 1e18;
        uint wethAmount = 10e18;

        int24 _tickLower;
        int24 _tickUpper;

        {
        uint priceLower = 800e18; // 800 usd
        uint priceUpper = 2000e18; // 2000 usd

        // uint160 sqrtPriceX96Lower = uni.priceToSqrtX96(priceLower);
        // uint160 sqrtPriceX96Upper = uni.priceToSqrtX96(priceUpper);
        uint160 sqrtPriceX96Lower =  2.5054144837504793e30;
        uint160 sqrtPriceX96Upper = 3.961408125713217e30;

        int24 rawTickLower = TickMath.getTickAtSqrtRatio(sqrtPriceX96Lower);
        int24 rawTickUpper = TickMath.getTickAtSqrtRatio(sqrtPriceX96Upper);

        // @dev how the fuck does this negative work?
        // _tickLower = -uni.roundToNearestTick(rawTickLower);
        // _tickUpper = uni.roundToNearestTick(rawTickUpper);

        _tickLower = rawTickLower;
        _tickUpper = rawTickUpper;

        }

        console.log("TICK LOWER");
        console.logInt(int(_tickLower));
        console.logInt(int(_tickUpper));
        
        (uint tokenId, 
        uint128 liquidityDelta,
        uint amount0, 
        uint amount1) = uni.mintNewPosition(
            DAI, 
            WETH, 
            daiAmount, 
            wethAmount, 
            _tickLower,
            _tickUpper);
        
        
        liquidity += liquidityDelta;

        console.log("--- Mint new position ---");
        console.log("token id", tokenId);
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);

        // Collect fees
        (uint fee0, uint fee1) = uni.collectAllFees(tokenId);

        console.log("--- Collect fees ---");
        console.log("fee 0", fee0);
        console.log("fee 1", fee1);


    }
}

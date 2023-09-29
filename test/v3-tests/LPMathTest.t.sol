// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

import "src/uni-v3/interfaces/IAave.sol";
import "src/uni-v3/interfaces/interfaces.sol";


import "src/uni-v3/UniswapV3LPHedger.sol";
import "src/uni-v3/Factory.sol";

contract UNIV3_IL_HEDGE is Test {
    address WETH = vm.envAddress("WETH_ETH");
    address USDC = vm.envAddress("USDC_ETH");

    UniswapV3LPHedger hedger;
    Factory factory;
    Leverage leverage;

    address aaveV3_pool = vm.envAddress("AAVEV3_POOL_ETH");

    address _nonfungiblePositionManager = vm.envAddress("nonfungiblePositionManager_ETH");

    function setUp() public {
        // ethFork = vm.createSelectFork(ETH_RPC);

        // deploy factory
        factory = new Factory(aaveV3_pool);

        // deploy leverage
        leverage = Leverage(factory.createLeverageContract());

        // deploy hedger
        hedger = new UniswapV3LPHedger(address(leverage));
    }

    function testOpenLPMath() public view {
        console.log("START");

        int24 tickLower = 69060; // ~1000 USDC/WETH
        int24 tickUpper = 78240; // ~2500 USDC/WETH

        uint160 p = TickMath.getSqrtRatioAtTick(73655);
        uint160 a = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 b = TickMath.getSqrtRatioAtTick(tickUpper);

        uint amountToken1 = 200e6;
        uint amountToken0 = 1e18;
        uint price = 1e12;

        uint portfolioValue = (price * amountToken1 / 1e18) + amountToken0 * 1e12;
        uint LP_value = ud(portfolioValue).mul(ud(0.79e18)).unwrap(); 

        (uint amountX, uint amountY) = hedger.get_liquidity_xy(p, a, b, LP_value);

        console.log("AMOUNTS");
        console.log(amountX);
        console.log(amountY);

    }
}
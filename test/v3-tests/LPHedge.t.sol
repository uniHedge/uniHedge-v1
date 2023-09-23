// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// forge std
import "forge-std/console.sol";
import "forge-std/Test.sol";

// prb-math v3
import { SD59x18, sd } from "@prb/math/SD59x18.sol";
import { UD60x18, ud, unwrap } from "@prb/math/UD60x18.sol";

import "src/uni-v3/UniswapV3LPHedger.sol";
import "src/uni-v3/Factory.sol";

contract shortTest is Test {
    uint ethFork;
    string ETH_RPC = vm.envString("ETH_RPC");

    address WETH = vm.envAddress("WETH_ETH");
    address USDC = vm.envAddress("USDC_ETH");

    UniswapV3LPHedger hedger;
    Factory factory;
    Leverage leverage;

    address aaveV3_pool = vm.envAddress("AAVEV3_POOL_ETH");

    function setUp() public {
        ethFork = vm.createSelectFork(ETH_RPC);

        // deploy factory
        // factory = new Factory(aaveV3_pool);

        // deploy leverage
        // leverage = Leverage(factory.createLeverageContract());

        hedger = new UniswapV3LPHedger(aaveV3_pool);
    }

/*     function getDAI() internal {
        IERC20 dai = IERC20(DAI);
        vm.prank(user);
        dai.approve(address(this), balance);
        vm.prank(user);
        // usdc.transfer(address(this), 2000e6);
    } */

    function testOpenLPHedge() public {
        // STEP #1 Get USDC 
        // getUSDC();
        deal(USDC, address(this), type(uint).max);
        deal(WETH, address(this), type(uint).max);

        // STEP #2 Approve leverage
        IERC20(USDC).approve(address(hedger), type(uint).max);
        IERC20(WETH).approve(address(hedger), type(uint).max);

        int24 tickLower = 66000;
        int24 tickUpper = 75960;

        hedger.openHedgedLP(USDC, WETH, 5000e18, 1e18, tickLower, tickUpper);

    }

}
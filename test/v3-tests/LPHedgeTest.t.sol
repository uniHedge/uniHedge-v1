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
    uint ethFork;
    string ETH_RPC = vm.envString("ETH_RPC");

    address WETH = vm.envAddress("WETH_ETH");
    address USDC = vm.envAddress("USDC_ETH");

    UniswapV3LPHedger hedger;
    Factory factory;
    Leverage leverage;

    address aaveV3_pool = vm.envAddress("AAVEV3_POOL_ETH");

    address _nonfungiblePositionManager = vm.envAddress("nonfungiblePositionManager_ETH");

    

    function setUp() public {
        ethFork = vm.createSelectFork(ETH_RPC);

        // deploy factory
        factory = new Factory(aaveV3_pool);

        // deploy leverage
        leverage = Leverage(factory.createLeverageContract());

        // deploy hedger
        hedger = new UniswapV3LPHedger(address(leverage));
    }

    function testOpenLPHedge() public {
        // STEP #1 Get USDC & WETH
        deal(USDC, address(this), type(uint).max);
        deal(WETH, address(this), type(uint).max);

        // STEP #2 Approve leverage
        IERC20(USDC).approve(address(hedger), type(uint).max);
        IERC20(WETH).approve(address(hedger), type(uint).max);

        int24 tickLower = 69060; // ~1000 USDC/WETH
        int24 tickUpper = 74940; // ~1800 USDC/WETH

        // STEP #3 Call OpenHedgeLP Function
        hedger.openHedgedLP(USDC, WETH, 5000e18, 2e18, tickLower, tickUpper);

        (uint tokenId, , , , , , ,) = hedger.userPositions(address(this));

        // Uniswap V3 LP position Data
        (/* uint96 nonce */,
        /* address operator  */,
        /* address token0 */,
        /* address token1 */ ,
        /* uint24 fee */,
        int24 _tickLower, 
        int24 _tickUpper, 
        uint128 liquidity,
        /* uint256 feeGrowthInside0LastX128 */,
        /* uint256 feeGrowthInside1LastX128 */,
        /* uint128 tokensOwed0 */, 
        /* uint128 tokensOwed1 */) = INonfungiblePositionManager(_nonfungiblePositionManager).positions(tokenId);
        
        // Aave Short Position Data
        (uint totalCollateralBase,
        uint totalDebtBase,
        /* uint availableBorrowBase */,
        /* uint currentLiquidationThreshold */,
        uint ltv,
        /* uint healthFactor */) = IPOOL(aaveV3_pool).getUserAccountData(address(leverage));

        console.log("**** UNISWAP V3 Liquidity Data ****");
        console.log(liquidity);
        console.log("- Lower tick");
        console.logInt(_tickLower);
        console.log("- Upper tick");
        console.logInt(_tickUpper);

        console.log(" ");

        console.log("**** AAVE SHORT Position Data ***");
        console.log(" - Borrowed WETH amount:");
        console.log(IERC20(WETH).balanceOf(address(hedger)));
        console.log(" - Total Collateral Base on Aave");
        console.log(totalCollateralBase);
        console.log(" - Total Debt Base on Aave");
        console.log(totalDebtBase);
        console.log(" - Loan to Value Ratio on Aave");
        console.log(ltv);

    


    }

}
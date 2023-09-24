// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/uni-v3/UniswapV3LPHedger.sol";
import "src/uni-v3/Factory.sol";

import "../Base.s.sol";

contract UniV3HedgeScript is BaseScript {
    address aaveV3_pool = vm.envAddress("AAVEV3_POOL_ETH");

    function run()
        public
        virtual
        broadcaster
        returns (Factory factory, Leverage leverage, UniswapV3LPHedger hedger)
    {
        // deploy factory
        factory = new Factory(aaveV3_pool);

        // deploy leverage
        leverage = Leverage(factory.createLeverageContract());

        // deploy hedger
        hedger = new UniswapV3LPHedger(address(leverage));
    }
}

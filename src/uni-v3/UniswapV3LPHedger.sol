// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "./interfaces/Interfaces.sol";
import {UD60x18, ud, unwrap} from "@prb/math/UD60x18.sol";
import "./Leverage.sol";
import "./Provider.sol";

import "forge-std/console.sol";

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapV3LPHedger is UniswapV3LiquidityProvider, Leverage {

    Leverage leverage;

    constructor(address _leverage) {
        leverage = Leverage(_leverage);
    }

    function testCallLEv(address token0, address token1, uint base, UD60x18 _leverage) external {
        leverage.short(token0, token1, base, _leverage);
    }

}

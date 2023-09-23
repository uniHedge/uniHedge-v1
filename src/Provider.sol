// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/Interfaces.sol";
import "forge-std/console.sol";

contract UniswapV3Liquidity is IERC721Receiver {

    int24 private constant MIN_TICK = -887272;
    int24 private constant MAX_TICK = -MIN_TICK;
    int24 private constant TICK_SPACING = 60;

    INonfungiblePositionManager public nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint /* tokenId */,
        bytes calldata /* data */
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function mintNewPosition(
        address token0,
        address token1,
        uint amount0ToAdd,
        uint amount1ToAdd
    ) external returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1) {
        IERC20(token0).transferFrom(msg.sender, address(this), amount0ToAdd);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1ToAdd);

        IERC20(token0).approve(address(nonfungiblePositionManager), amount0ToAdd);
        IERC20(token1).approve(address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: 3000, // @dev make this customizable
                tickLower: (MIN_TICK / TICK_SPACING) * TICK_SPACING,
                tickUpper: (MAX_TICK / TICK_SPACING) * TICK_SPACING,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(
            params
        );

        if (amount0 < amount0ToAdd) {
            IERC20(token0).approve(address(nonfungiblePositionManager), 0);
            uint refund0 = amount0ToAdd - amount0;
            IERC20(token0).transfer(msg.sender, refund0);
        }
        if (amount1 < amount1ToAdd) {
            IERC20(token1).approve(address(nonfungiblePositionManager), 0);
            uint refund1 = amount1ToAdd - amount1;
            IERC20(token1).transfer(msg.sender, refund1);
        }
    }

    function collectAllFees(
        uint tokenId
    ) external returns (uint amount0, uint amount1) {
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }

    function increaseLiquidityCurrentRange(
        uint tokenId,
        uint amount0ToAdd,
        uint amount1ToAdd
    ) external returns (uint128 liquidity, uint amount0, uint amount1) {

         // (uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1)
        (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(tokenId);

        IERC20(token0).transferFrom(msg.sender, address(this), amount0ToAdd);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1ToAdd);

        IERC20(token0).approve(address(nonfungiblePositionManager), amount0ToAdd);
        IERC20(token1).approve(address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(
            params
        );
    }

    function decreaseLiquidityCurrentRange(
        uint tokenId,
        uint128 liquidity
    ) external returns (uint amount0, uint amount1) {
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
    }
}


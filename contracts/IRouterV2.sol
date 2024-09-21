// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


interface IRouterV2 {
    function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
    ) external returns (uint[] memory amounts);
}

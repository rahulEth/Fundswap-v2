pragma solidity >=0.5.0;

interface IFundswapV2Callee {
    function fundswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
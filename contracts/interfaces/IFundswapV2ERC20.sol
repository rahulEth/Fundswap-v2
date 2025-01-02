pragma solidity ^0.5.16;

interface IUniswapV2ERC20{

    event Approval(address indexed owner, address indexed spender, uint value);
    event Trasfer(address indexed from, address indexed to, uint value);
    
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function  decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allownace(address owner , address spender) external view returns (uint);
     
    function trasfer(address to, uint value) external returns(bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPERATOR() external view returns (bytes32);
    function PERMIT_HASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint8);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;   

}
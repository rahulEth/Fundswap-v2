// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

import './interfaces/IUniswapV2ERC20.sol';
import './interfaces/SafeMath.sol';

contract UniswapV2ERC20 is  IUniswapV2ERC20{
    using SafeMath for uint;

    string public constant name = 'Fundswap V2';
    string public constant symbol = 'FUD-V2';
    uint8 constant public decimals = 18;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allownace;

    bytes32 public DOMAIN_SEPERATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Trasfer(address indexed from, address indexed to, uint value);

    constructor(){
        uint chainId;
        assembly { 
            chainId := chainid 
        }
        DOMAIN_SEPERATOR = keccak256(
                    abi.encode(
                        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                        keccak256(byte(name)),
                        keccak256(byte(1)),
                        chainId,
                        address(this)
                    )
        );

    }


    function _mint(address to , uint value) internal{
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Trasfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal{
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub( value);
        emit Trasfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal private{
        allownace[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal private{
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Trasfer(from, to, value);

    }

    function approve(address spender, uint value) external returns(bool){
        _approve(msg.sender, spender, value);
        return true;

    }

    function trasfer(address to, uint value) external returns(bool){
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        // If the allowance for the caller is not the maximum possible value (uint(-1)), it decreases the allowance by value using sub
        // if condition is flse mean allowance in infinte not decremental
        if(allownace[from][msg.sender] != uint(-1)){
            allownace[from][msg.sender] = allowance[from][msg.sender].sub(value);
        } 
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner , address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external{
        require(deadline >= block.timestamp, "Fundswap V2");
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPERATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce[owner]++, deadline))
         
            );
        )

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "FundswapV2: INVALID_SIGNATURE");
        _approval(owner, spender, value);

    }  
}




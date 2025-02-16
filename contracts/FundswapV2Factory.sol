pragma solidity =0.5.16;

import './interfaces/IFundswapV2Factory.sol';
import './FundswapV2Pair.sol';
import './FundswapV2ERC20.sol';



contract FundswapV2Factory is IFundswapV2Factory {
   address public feeTo;
   address public feeToSetter;

   mapping(address => mapping(address => address)) public getPair;
   address[] public allPairs;

   event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public{
      feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns(uint){
        return allPairs.length;
    }

    function setFeeTo(address _feeTo) external{
        require(msg.sender == feeToSetter, 'FundswapV2: FORBIDDEN');
        feeTo = _feeTo;
    } 

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'FundswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }


    function createPair(address tokenA, address tokenB) external returns (address pair){
        require(tokenA != tokenB, 'FundswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(getPair[token0][token1] == address(0), 'FundswapV2: PAIR_EXISTS');
        bytes memory bytecode = type(FundswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // pair = address(new FundswapV2Pair());
        FundswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }


}



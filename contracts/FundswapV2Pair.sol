//SPDX-Licence-Identifier: MIT
pragma solidity ^0.5.16;

import './interfaces/IFundswapV2Pair.sol';
import './FundswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112*112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IFundswapV2Factory.sol';
import './interfaces/IFundswapV2Callee.sol';


contract FundswapV2Pair is IUniswapV2Pair, FundswapV2ERC20{
    using SafeMath for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 public reserve0;
    uint112 public reserve1;
    uint32 private blockTimestampLast;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;

    modifier lock(){
        require(unlocked == 1, 'FundswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    event Sync(uint112 amount0, uint112 amount1);

    constructor() public{
        factory = msg.sender;
    }

   // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external{
         token0 = _token0;
         token1 = _token1;  
    }

    function getReserves() public view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast){
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // this low-level function should be called from a contract which performs important safety checks
    
    function mint(address to) external lock returns (uint liquidity){
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint balace0 = IERC20(token0).balanceOf(address(this));
        uint balace1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balace0.sub(_reserve0);
        uint amount1 = balace1.sub(_reserve1);
        
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply;
        if(_totalSupply == 0){
            // For the first provider, the liquidity minted is proportional to the geometric mean of the token amounts (sqrt(amount0 * amount1)), minus MINIMUM_LIQUIDITY.
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            // This prevents issues with division by zero and ensures a base liquidity level.
            _mint(address(0), liquidity); // permanently lock the first MINIMUM_LIQUIDITY tokens
        }else{
            // for subsequent providers , it would be propotional to the smaller of 2 deposit amout relative to exising reserves
            liquidity = Math.min(
                amount0.mul(_totalSupply)/_reserve0, 
                amount1.mul(_totalSupply)/_reserve1
            );

        }

        require(liquidity > 0, 'FundswapV2: INSUFFICIENT_LIQUIDTY MINTED');

        _mint(to, liquidity);

        _update(balace0, balace1, _reserve0, _reserve1);

        if(feeOn) kLast = uint(reserve0).mul(reserve1);

        emit Mint(msg.sender, amount0, amount1);
    }

   // this low level funcion cal shoud be called from a contract that implement saftey checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata   data) external lock{
        require(amount0Out > 0 || amount1Out > 0, 'FundswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
         require(amount0Out < _reserve0 && amount1Out < _reserve1, 'FundswapV2: INSUFFICIENT_LIQUIDITY'); 

        uint balance0;
        uint baance1;
        {
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'FundswapV2: INVALID_TO');  
            if(amount0Out > 0) _safeTrasfer(_token, to, amount0Out); // optimistically transfer tokens
            if(amount1Out > 0) _safeTrasfer(_token, to, amount1Out); // optimistically transfer tokens
            if(data.length > 0) IFundswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data); 
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC(_token1).balanceOf(address(this));
        } 

        uint amount0In = balance0 > (_reserve0 - amount0Out) ?  balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > (_reserve1 - amount1Out) ?  balance1 - (_reserve1 - amount1Out) : 0;  
        {
            uint balance0Adjected = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjected = balance1.mul(1000).sub(amount1In.mul(3));
            require(balance0Adjected.mul(balance1Adjected) >= uint(_reserve0).mul(_reserve1).mul(1000**2), "FundswapV2: k");
        }  

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);

    }
    
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn){
        address feeTo = IFundswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);  //If feeTo is not address(0), fees are enabled,
        uint _kLast = kLast;
        if(feeOn){
            if(kLast !=0){
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast){
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    // calculating adition liquidty if feeOn is true and reserves increases 
                    uint liquidity = numerator / denominator;
                    if(liquidity > 0 ) _mint(feeTo, liquidity);
                }
            }
        }else if (_kLast !=0){
              kLast = 0;
        }
    }

        // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }


    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'FundswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32( block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        
        if(timeElapsed !=0 && _reserve0 !=0 && _reserve1 !=0){

        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);

    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

}







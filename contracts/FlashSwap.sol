// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.6;

import "hardhat/console.sol";
import "./lib/UniswapV2Library.sol";
import "./lib/SafeERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IERC20.sol";

/**
 * @title FlashSwap
 * @dev Flash swap contract to engage in arbitrage on the bsc network
 */
contract FlashSwap {
    using SafeERC20 for IERC20; // For approval
    
    // From pancakeswap doc v2
    address private constant PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // from BscScan
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955; // Binance peg
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant CROX = 0x2c094F5A7D1146BB93850f629501eB749f6Ed491;

    uint256 private deadline = block.timestamp + 1 days;
    uint256 private constant MAX_INT = 2**256 - 1;

    /**
    * @dev Funds the contract with tokens
    */
    function fundContract(address holder, address token, uint256 amount) public {
        IERC20(token).safeTransferFrom(holder, address(this), amount);
    }

    /**
    * @dev Get the balance of a token in the contract
    */
    function getBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
    * @dev Receive loan to engage in arbitrage
    * @param borrow user who initiated the flash loan
    */
    function initArbitrage(address borrow, uint256 amount) external {
        IERC20(BUSD).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(USDT).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(CROX).safeApprove(address(PANCAKE_ROUTER), MAX_INT);
        IERC20(CAKE).safeApprove(address(PANCAKE_ROUTER), MAX_INT);

        // Get the pair address
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(borrow, WBNB);
        require(pair != address(0), "Pair does not exist");

        // Find which token holds the amount
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1(); 
        uint256 amount0Out = borrow == token0 ? amount : 0;
        uint256 amount1Out = borrow == token1 ? amount : 0;
    
        // encode the data so we can pass it to the swap function
        bytes memory data = abi.encode(borrow, amount);

        // Get loan
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }
    
    /**
    * @dev Swap tokens on pancakeswap
    * @param sender user who initiated the swap 
    */
    function pancakeSwap(address sender, uint256 amount) external {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(PANCAKE_FACTORY).getPair(token0, token1);

        require(pair == msg.sender, "Unauthorized");
        require(sender == address(this), "Unauthorized");

        // Decode the data we encoded in the swap function
        (address borrow, uint256 amount) = abi.decode(msg.data, (address, uint256));

        // Calculate the fee to pay back
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 repayAmount = amount + fee;

        // Pay back loan
        IERC20(borrow).safeTransfer(pair, repayAmount);
    }
}
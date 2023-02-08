const { expect, assert } = require('chai');
const { ethers } = require('hardhat');
const { impersonateFundErc20 } = require('../util/utilities');
const { inputToConfig } = require("@ethereum-waffle/compiler");
const { abi } = require('../artifacts/contracts/interfaces/IERC20.sol/IERC20.json');

const provider = waffle.provider;

describe('Simulate arbitrage and test smart contract', function () {
    const DECIMALS = 18;
    const WHALE_ADDRESS = "0xf977814e90da44bfa03b6295a0616a897441acec";
    const WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
    const BUSD = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
    const USDT = "0x55d398326f99059fF775485246999027B3197955";
    const CAKE = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82";
    const CROX = "0x2c094F5A7D1146BB93850f629501eB749f6Ed491";

    let FLASHSWAP, BORROW_AMOUNT, FUND_AMOUNT, initFundingHuman, txArbitrage, gasUsedUSD;

    const tokenBase = new ethers.Contract(BUSD, abi, provider);

    beforeEach(async () => {
        [owner] = await ethers.getSigners();

        // whale needs balance
        const whaleBalance = await provider.getBalance(WHALE_ADDRESS);
        expect(whaleBalance).not.equal("0");

        // deploy flashswap contract
        const flashSwap = await ethers.getContractFactory('FlashSwap');
        FLASHSWAP = await flashSwap.deploy();
        await FLASHSWAP.deployed();

        // configure
        const borrowAmount = "1";
        BORROW_AMOUNT = ethers.utils.parseUnits(borrowAmount, DECIMALS);
        initFundingHuman = "100";
        FUND_AMOUNT = ethers.utils.parseUnits(initFundingHuman, DECIMALS);

        // fund for testing
        await impersonateFundErc20(tokenBase, WHALE_ADDRESS, FLASHSWAP.address, initFundingHuman);
    });

    describe("Arbitrage tests", function () {

        it("Contract is funded with 100 BUSD", async function () {
            const balance = await FLASHSWAP.getBalance(BUSD);
            const balanceHuman = ethers.utils.formatUnits(balance, DECIMALS);

            expect(Number(balanceHuman)).to.equal(Number(initFundingHuman));
        });

        it("Executes arbitrage", async function () {
            txArbitrage = await FLASHSWAP.startArbitrage(BUSD, BORROW_AMOUNT);

            assert(txArbitrage);

            const contractBalance = await FLASHSWAP.getBalance(BUSD);
            const contractBalanceHuman = ethers.utils.formatUnits(contractBalance, DECIMALS);

            console.log("Contract balance after arbitrage: ", contractBalanceHuman);
        });

    });
});
require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-waffle");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
const defaultConfig = {
  optimizer: {
    enabled: true,
    runs: 200,
  }
}

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.5.5",
        settings: defaultConfig,
      },
      {
        version: "0.6.6",
        settings: defaultConfig,
      },
      {
        version: "0.8.8",
        settings: defaultConfig,
      },
    ]
  },
  networks: {
    hardhat: {
      forking: {
        // https://docs.bnbchain.org/docs/rpc/
        url: "https://bsc-dataseed.binance.org"
      }
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      // get token from env
      accounts:  JSON.parse(process.env.PRIVATE_KEY)
    }
  }
};

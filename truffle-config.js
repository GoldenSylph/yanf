require('dotenv').config();
const HDWalletProvider = require('truffle-hdwallet-provider');

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },
    kovan: {
      provider: function() {
        return new HDWalletProvider(
          process.env.MNEMONIC,
          `https://kovan.infura.io/v3/${process.env.INFURA_API_KEY}`
        )
      },
      gas: 7900000,
      gasPrice: 1000000000,
      network_id: 42
    }
  },
  compilers: {
    solc: {
      version: "^0.5.2",
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
};

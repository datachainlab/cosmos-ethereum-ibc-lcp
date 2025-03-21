require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-contract-sizer");

/**
 * @type import('hardhat/config').HardhatUserConfig
 * @notice `contracts/App.sol` is compiled with different settings because AppV7's size exceeds the contract size limit if viaIR is enabled
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.28",
        settings: {
          evmVersion: "cancun",
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 9_999_999
          }
        }
      }
    ],
    overrides: {
      "contracts/App.sol": {
        version: "0.8.28",
        settings: {
          evmVersion: "cancun",
          viaIR: false,
          optimizer: {
            enabled: true,
            runs: 9_999_999
          }
        }
      }
    }
  },
  networks: {
    eth_local: {
      url: 'http://geth:8546'
    }
  }
}

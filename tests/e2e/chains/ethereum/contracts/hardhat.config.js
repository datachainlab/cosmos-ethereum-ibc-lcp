require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      evmVersion: "cancun",
      optimizer: {
        enabled: true,
        runs: 9_999_999
      }
    },
  },
  networks: {
    eth_local: {
      url: 'http://geth:8546',
      accounts: [
	'e517af47112e4f501afb26e4f34eadc8b0ad8eadaf4962169fc04bc8ddbfe091',
	'713071a0b7101f177ae9c9ab0412eb7e43812bd289650f8db63f3055f2bcb029'
      ]
    }
  }
}

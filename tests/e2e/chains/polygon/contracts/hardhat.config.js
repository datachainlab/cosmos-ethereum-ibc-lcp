require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-contract-sizer");

// bor's JSON-RPC URL is dynamic (kurtosis port forwarding). The Makefile resolves
// it via `make -s -C ../.. bor-rpc-url` and injects it as BOR_RPC_URL.
const borRpcUrl = process.env.BOR_RPC_URL || "http://localhost:8545";

// Polygon PoS kurtosis devnet admin private key — the only L2-prefunded account
// (see https://github.com/0xPolygon/kurtosis-pos: corresponds to
// 0x74Ed6F462Ef4638dc10FFb05af285e8976Fb8DC9).
const kurtosisAdminPrivateKey = "0xd40311b5a5ca5eaeb48dfba5403bde4993ece8eccf4190e98e19fcd4754260ea";

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
    bor_local: {
      url: borRpcUrl,
      accounts: [kurtosisAdminPrivateKey]
    }
  }
};

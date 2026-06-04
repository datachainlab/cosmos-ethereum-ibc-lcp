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

// Private key whose address matches the relayer's HD-signer EOA
// (mnemonic "math razor capable ..." / m/44'/60'/0'/0/0 →
// 0xa89F47C6b463f74d87572b058427dA0A13ec5425). Used by deploy.js to deploy the
// App contracts so that `_deployer == owner() == relayer signer`, otherwise
// `eth upgrade propose` reverts with IBCChannelUpgradableModuleUnauthorizedUpgrader.
const relayerPrivateKey = "0xe517af47112e4f501afb26e4f34eadc8b0ad8eadaf4962169fc04bc8ddbfe091";

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
      // Order matters — deploy.js uses [0] (admin) to fund [1] (relayer EOA),
      // then [1] for the actual contract deploys so it ends up as `_deployer`.
      accounts: [kurtosisAdminPrivateKey, relayerPrivateKey]
    }
  }
};

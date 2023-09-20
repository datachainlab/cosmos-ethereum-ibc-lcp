module.exports = {
  networks: {
    eth_local: {
      host: '127.0.0.1',
      port: 8546,
      network_id: '15'
    }
  },
  compilers: {
    solc: {
      version: '0.8.21',
      settings: {
        optimizer: {
          enabled: true,
          runs: 1000
        }
      }
    }
  }
};

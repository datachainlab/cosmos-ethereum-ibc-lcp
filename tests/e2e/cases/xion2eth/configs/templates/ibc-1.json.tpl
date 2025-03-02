{
  "chain": {
    "@type": "/relayer.chains.ethereum.config.ChainConfig",
    "chain_id": "ibc1",
    "eth_chain_id": 15,
    "rpc_addr": "http://localhost:8546",
    "signer": {
      "@type": "/relayer.signers.hd.SignerConfig",
      "mnemonic": "math razor capable expose worth grape metal sunset metal sudden usage scheme",
      "path": "m/44'/60'/0'/0/0"
    },
    "ibc_address": $IBC_ADDRESS,
    "initial_send_checkpoint": 0,
    "initial_recv_checkpoint": 0,
    "enable_debug_trace": true,
    "average_block_time_msec": 6000,
    "max_retry_for_inclusion": 5,
    "allow_lc_functions": {
      "lc_address": $LC_ADDRESS,
      "selectors": [
        "0xa97c61d6",
        "0x6ac73aa0"
      ]
    },
    "gas_estimate_rate": {
      "numerator": 3,
      "denominator": 2
    },
    "max_gas_limit": 10000000,
    "tx_type": "auto",
    "blocks_per_event_query": 1000,
    "abi_paths": ["../../chains/ethereum/contracts/abis"],
    "price_bump": 10
  },
  "prover": {
    "@type": "/relayer.provers.cosmwasm.config.ProverConfig",
    "origin_prover": {
      "@type": "/relayer.provers.ethereum_light_client.config.ProverConfig",
      "beacon_endpoint": "http://localhost:19596",
      "network": "minimal",
      "trusting_period": "168h",
      "max_clock_drift": "0",
      "refresh_threshold_rate": {
        "numerator": 2,
        "denominator": 3
      }
    },
    "checksum": $WASM_CODE_CHECKSUM
  }
}

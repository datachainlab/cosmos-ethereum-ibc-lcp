{
  "chain": {
    "@type": "/relayer.chains.ethereum.config.ChainConfig",
    "chain_id": "ibc0",
    "eth_chain_id": 4927,
    "rpc_addr": $BOR_ENDPOINT,
    "signer": {
      "@type": "/relayer.signers.hd.SignerConfig",
      "mnemonic": "math razor capable expose worth grape metal sunset metal sudden usage scheme",
      "path": "m/44'/60'/0'/0/0"
    },
    "ibc_address": $IBC_ADDRESS,
    "initial_send_checkpoint": 0,
    "initial_recv_checkpoint": 0,
    "enable_debug_trace": true,
    "average_block_time_msec": 1000,
    "max_retry_for_inclusion": 5,
    "gas_estimate_rate": {
      "numerator": 3,
      "denominator": 2
    },
    "max_gas_limit": 10000000,
    "tx_type": "auto",
    "blocks_per_event_query": 1000,
    "abi_paths": []
  },
  "prover": {
    "@type": "/relayer.provers.lcp.config.ProverConfig",
    "origin_prover": {
      "@type": "/relayer.provers.polygon.config.ProverConfig",
      "heimdall_cometbft_endpoint": $HEIMDALL_COMETBFT_ENDPOINT,
      "heimdall_cosmos_endpoint": $HEIMDALL_COSMOS_ENDPOINT,
      "heimdall_chain_id": $HEIMDALL_CHAIN_ID,
      "trusting_period": "24h",
      "max_clock_drift": "0",
      "refresh_threshold_rate": {
        "numerator": 2,
        "denominator": 3
      }
    },
    "lcp_service_address": "localhost:50051",
    "mrenclave": $MRENCLAVE,
    "allowed_quote_statuses": ["GROUP_OUT_OF_DATE"],
    "allowed_advisory_ids": ["INTEL-SA-00219","INTEL-SA-00289","INTEL-SA-00334","INTEL-SA-00477","INTEL-SA-00614","INTEL-SA-00615","INTEL-SA-00617", "INTEL-SA-00828"],
    "key_expiration": 604800,
    "key_update_buffer_time": 3600,
    "elc_client_id": "polygon-0",
    "message_aggregation": true,
    "is_debug_enclave": true
  }
}

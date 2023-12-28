{
  "chain": {
    "@type": "/relayer.chains.ethereum.config.ChainConfig",
    "chain_id": "ibc1",
    "eth_chain_id": 15,
    "rpc_addr": "http://localhost:8546",
    "signer": {
      "@type": "/relayer.chains.ethereum.signers.hd.SignerConfig",
      "mnemonic": "math razor capable expose worth grape metal sunset metal sudden usage scheme",
      "path": "m/44'/60'/0'/0/0"
    },
    "ibc_address": "0x2F5703804E29F4252FA9405B8D357220d11b3bd9",
    "initial_send_checkpoint": 0,
    "initial_recv_checkpoint": 0,
    "enable_debug_trace": true,
    "average_block_time_msec": 6000,
    "max_retry_for_inclusion": 5
  },
  "prover": {
    "@type": "/relayer.provers.lcp.config.ProverConfig",
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
    "lcp_service_address": "localhost:50051",
    "mrenclave": "$MRENCLAVE",
    "allowed_quote_statuses": ["GROUP_OUT_OF_DATE"],
    "allowed_advisory_ids": ["INTEL-SA-00219","INTEL-SA-00289","INTEL-SA-00334","INTEL-SA-00477","INTEL-SA-00614","INTEL-SA-00615","INTEL-SA-00617", "INTEL-SA-00828"],
    "key_expiration": 604800,
    "elc_client_id": "ethereum-0",
    "message_aggregation": true
  }
}

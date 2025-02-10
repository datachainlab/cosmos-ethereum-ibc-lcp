{
  "chain": {
    "@type": "/relayer.chains.tendermint.config.ChainConfig",
    "key": "testkey",
    "chain_id": "ibc1",
    "rpc_addr": "http://localhost:26557",
    "account_prefix": "xion",
    "gas_adjustment": 1.5,
    "gas_prices": "0.025stake",
    "average_block_time_msec": 1000,
    "max_retry_for_commit": 5
  },
  "prover": {
    "@type": "/relayer.provers.lcp.config.ProverConfig",
    "origin_prover": {
      "@type": "/relayer.chains.tendermint.config.ProverConfig",
      "trusting_period": "336h",
      "refresh_threshold_rate": {
        "numerator": 2,
        "denominator": 3
      }
    },
    "lcp_service_address": "localhost:50051",
    "mrenclave": $MRENCLAVE,
    "allowed_quote_statuses": ["SW_HARDENING_NEEDED", "GROUP_OUT_OF_DATE"],
    "allowed_advisory_ids": ["INTEL-SA-00219","INTEL-SA-00289","INTEL-SA-00334","INTEL-SA-00477","INTEL-SA-00614","INTEL-SA-00615","INTEL-SA-00617", "INTEL-SA-00828"],
    "key_expiration": 604800,
    "elc_client_id": "07-tendermint-1",
    "message_aggregation": true,
    "is_debug_enclave": true,
    "operators": [
      "0x9722414d09f43fb02235d739B50F4C027F43e657"
    ],
    "operator_signer": {
      "@type": "/relayer.provers.lcp.signers.raw.SignerConfig",
      "private_key": "0x8a94e9f944a297c402a997aa9a60026ce47a6e018192d111c1703176bbc26651"
    },
    "operators_eip712_cosmos_chain_params": {
      "chain_id": "ibc0",
      "prefix": "ibc"
    }
  }
}

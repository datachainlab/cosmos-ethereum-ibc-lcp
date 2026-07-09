#!/bin/sh
set -eux

# Resolve directories relative to this script so cwd doesn't matter
# (callers run us both from the repo root and from tm2pol/).
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CASE_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
POL_CHAIN_DIR=${POL_CHAIN_DIR:-$(cd "${CASE_DIR}/../../chains/polygon" && pwd)}

TEMPLATE_DIR=${CASE_DIR}/configs/templates
CONFIG_DIR=${CASE_DIR}/configs/demo
ADDRESSES_DIR=${POL_CHAIN_DIR}/contracts/addresses

IS_DEBUG_ENCLAVE=false
if [ "$LCP_ENCLAVE_DEBUG" = "1" ]; then
    IS_DEBUG_ENCLAVE=true
fi
: "${LCP_KEY_EXPIRATION:?must be set}"
: "${LCP_MRENCLAVE:?must be set (export from \`lcp enclave metadata\`)}"

ZKDCAP=${ZKDCAP:-false}
LCP_ZKDCAP_RISC0_MOCK=${LCP_ZKDCAP_RISC0_MOCK:-false}

# Bor + heimdall endpoints from kurtosis-pos. Allow override for offline edits.
BOR_ENDPOINT=${BOR_ENDPOINT:-$(make -s -C "${POL_CHAIN_DIR}" bor-rpc-url)}
HEIMDALL_COMETBFT_ENDPOINT=${HEIMDALL_COMETBFT_ENDPOINT:-$(make -s -C "${POL_CHAIN_DIR}" heimdall-cometbft-url)}
HEIMDALL_COSMOS_ENDPOINT=${HEIMDALL_COSMOS_ENDPOINT:-$(make -s -C "${POL_CHAIN_DIR}" heimdall-rest-url)}
HEIMDALL_CHAIN_ID=${HEIMDALL_CHAIN_ID:-heimdall-4927}

: "${BOR_ENDPOINT:?empty — is the kurtosis devnet up at ${POL_CHAIN_DIR}?}"
: "${HEIMDALL_COMETBFT_ENDPOINT:?empty — is the kurtosis devnet up at ${POL_CHAIN_DIR}?}"
: "${HEIMDALL_COSMOS_ENDPOINT:?empty — is the kurtosis devnet up at ${POL_CHAIN_DIR}?}"

# Deployed contract addresses produced by `make -C chains/polygon deploy extract-abi`.
IBC_ADDRESS=$(cat "${ADDRESSES_DIR}/IBCHandler")
LC_ADDRESS=$(cat "${ADDRESSES_DIR}/LCPClient")

mkdir -p "${CONFIG_DIR}"

if [ "${ZKDCAP}" = "true" ]; then
    : "${LCP_RISC0_IMAGE_ID:?must be set when ZKDCAP=true}"
    TPL_SUFFIX="-zkdcap"
else
    TPL_SUFFIX=""
fi

jq -n -f "${TEMPLATE_DIR}/ibc-0${TPL_SUFFIX}.json.tpl" \
    --arg MRENCLAVE "${LCP_MRENCLAVE}" \
    --argjson IS_DEBUG_ENCLAVE "${IS_DEBUG_ENCLAVE}" \
    --argjson LCP_KEY_EXPIRATION "${LCP_KEY_EXPIRATION}" \
    --arg LC_ADDRESS "${LC_ADDRESS}" \
    --arg RISC0_IMAGE_ID "${LCP_RISC0_IMAGE_ID:-}" \
    --argjson LCP_ZKDCAP_RISC0_MOCK "${LCP_ZKDCAP_RISC0_MOCK}" \
    > "${CONFIG_DIR}/ibc-0.json"

jq -n -f "${TEMPLATE_DIR}/ibc-1${TPL_SUFFIX}.json.tpl" \
    --arg MRENCLAVE "${LCP_MRENCLAVE}" \
    --argjson IS_DEBUG_ENCLAVE "${IS_DEBUG_ENCLAVE}" \
    --argjson LCP_KEY_EXPIRATION "${LCP_KEY_EXPIRATION}" \
    --arg IBC_ADDRESS "${IBC_ADDRESS}" \
    --arg LC_ADDRESS "${LC_ADDRESS}" \
    --arg BOR_ENDPOINT "${BOR_ENDPOINT}" \
    --arg HEIMDALL_COMETBFT_ENDPOINT "${HEIMDALL_COMETBFT_ENDPOINT}" \
    --arg HEIMDALL_COSMOS_ENDPOINT "${HEIMDALL_COSMOS_ENDPOINT}" \
    --arg HEIMDALL_CHAIN_ID "${HEIMDALL_CHAIN_ID}" \
    --arg RISC0_IMAGE_ID "${LCP_RISC0_IMAGE_ID:-}" \
    --argjson LCP_ZKDCAP_RISC0_MOCK "${LCP_ZKDCAP_RISC0_MOCK}" \
    > "${CONFIG_DIR}/ibc-1.json"

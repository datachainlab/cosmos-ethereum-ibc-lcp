#!/bin/sh
set -eux

# Resolve directories relative to this script so cwd doesn't matter
# (callers run us both from the repo root and from tm2pol/).
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CASE_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
POL_CHAIN_DIR=${POL_CHAIN_DIR:-$(cd "${CASE_DIR}/../../chains/polygon" && pwd)}

TEMPLATE_DIR=${CASE_DIR}/configs/templates
CONFIG_DIR=${CASE_DIR}/configs/demo

# Endpoints come from kurtosis-pos. Allow override for offline edits. A failed
# `make -s -C` in command substitution doesn't abort the parent under set -e
# (only the subshell), so post-check with ${VAR:?...} which propagates correctly.
BOR_ENDPOINT=${BOR_ENDPOINT:-$(make -s -C "${POL_CHAIN_DIR}" bor-rpc-url)}
HEIMDALL_COMETBFT_ENDPOINT=${HEIMDALL_COMETBFT_ENDPOINT:-$(make -s -C "${POL_CHAIN_DIR}" heimdall-cometbft-url)}
HEIMDALL_COSMOS_ENDPOINT=${HEIMDALL_COSMOS_ENDPOINT:-$(make -s -C "${POL_CHAIN_DIR}" heimdall-rest-url)}
HEIMDALL_CHAIN_ID=${HEIMDALL_CHAIN_ID:-heimdall-4927}

: "${BOR_ENDPOINT:?empty — is the kurtosis devnet up at ${POL_CHAIN_DIR}?}"
: "${HEIMDALL_COMETBFT_ENDPOINT:?empty — is the kurtosis devnet up at ${POL_CHAIN_DIR}?}"
: "${HEIMDALL_COSMOS_ENDPOINT:?empty — is the kurtosis devnet up at ${POL_CHAIN_DIR}?}"

# No solidity contracts deployed in Phase 1 — placeholder for storage proof queries.
IBC_ADDRESS=${IBC_ADDRESS:-0xFF00000000000000000000000000000000000000}

: "${LCP_MRENCLAVE:?must be set (export from \`lcp enclave metadata\`)}"

mkdir -p "${CONFIG_DIR}"

jq -n -f "${TEMPLATE_DIR}/ibc-0.json.tpl" \
    --arg MRENCLAVE "${LCP_MRENCLAVE}" \
    --arg IBC_ADDRESS "${IBC_ADDRESS}" \
    --arg BOR_ENDPOINT "${BOR_ENDPOINT}" \
    --arg HEIMDALL_COMETBFT_ENDPOINT "${HEIMDALL_COMETBFT_ENDPOINT}" \
    --arg HEIMDALL_COSMOS_ENDPOINT "${HEIMDALL_COSMOS_ENDPOINT}" \
    --arg HEIMDALL_CHAIN_ID "${HEIMDALL_CHAIN_ID}" \
    > "${CONFIG_DIR}/ibc-0.json"

# ibc-1 is a tendermint stub — `lcp create-elc <path>` loads both endpoints of
# the path even though it only operates on src, so a placeholder counterparty
# chain config is required. The endpoint is never actually dialed in Phase 1.
cp "${TEMPLATE_DIR}/ibc-1.json" "${CONFIG_DIR}/ibc-1.json"

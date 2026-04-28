#!/bin/sh
set -ex

POL_CHAIN_DIR=${POL_CHAIN_DIR:-tests/e2e/chains/polygon}

TEMPLATE_DIR=${E2E_TEST_DIR}/configs/templates
CONFIG_DIR=${E2E_TEST_DIR}/configs/demo

# Endpoints come from kurtosis-pos. Allow override for offline edits.
BOR_ENDPOINT=${BOR_ENDPOINT:-$(make -s -C ${POL_CHAIN_DIR} bor-rpc-url)}
HEIMDALL_COMETBFT_ENDPOINT=${HEIMDALL_COMETBFT_ENDPOINT:-$(make -s -C ${POL_CHAIN_DIR} heimdall-cometbft-url)}
HEIMDALL_COSMOS_ENDPOINT=${HEIMDALL_COSMOS_ENDPOINT:-$(make -s -C ${POL_CHAIN_DIR} heimdall-rest-url)}
HEIMDALL_CHAIN_ID=${HEIMDALL_CHAIN_ID:-heimdall-4927}

# No solidity contracts deployed in Phase 1 — placeholder for storage proof queries.
IBC_ADDRESS=${IBC_ADDRESS:-0xFF00000000000000000000000000000000000000}

mkdir -p ${CONFIG_DIR}

jq -n -f ${TEMPLATE_DIR}/ibc-0.json.tpl \
    --arg MRENCLAVE ${LCP_MRENCLAVE} \
    --arg IBC_ADDRESS ${IBC_ADDRESS} \
    --arg BOR_ENDPOINT ${BOR_ENDPOINT} \
    --arg HEIMDALL_COMETBFT_ENDPOINT ${HEIMDALL_COMETBFT_ENDPOINT} \
    --arg HEIMDALL_COSMOS_ENDPOINT ${HEIMDALL_COSMOS_ENDPOINT} \
    --arg HEIMDALL_CHAIN_ID ${HEIMDALL_CHAIN_ID} \
    > ${CONFIG_DIR}/ibc-0.json

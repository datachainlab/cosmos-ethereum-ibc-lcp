#!/bin/sh
set -ex

IS_DEBUG_ENCLAVE=false
if [ "$LCP_ENCLAVE_DEBUG" = "1" ]; then
    IS_DEBUG_ENCLAVE=true
fi

TEMPLATE_DIR=${E2E_TEST_DIR}/configs/templates
CONFIG_DIR=${E2E_TEST_DIR}/configs/demo

ADDRESSES_DIR=./tests/e2e/chains/ethereum/contracts/addresses

IBC_ADDRESS=$(cat $ADDRESSES_DIR/IBCHandler)
LC_ADDRESS=$(cat $ADDRESSES_DIR/LCPClient)

mkdir -p $CONFIG_DIR
if [ "$ZKDCAP" = true ]; then
    jq -n \
        --arg MRENCLAVE ${LCP_MRENCLAVE} \
        --argjson IS_DEBUG_ENCLAVE ${IS_DEBUG_ENCLAVE} \
        --arg LC_ADDRESS ${LC_ADDRESS} \
        --arg RISC0_IMAGE_ID ${LCP_RISC0_IMAGE_ID} \
        -f ${TEMPLATE_DIR}/ibc-0-zkdcap.json.tpl > ${CONFIG_DIR}/ibc-0.json

    jq -n \
        --arg MRENCLAVE ${LCP_MRENCLAVE} \
        --argjson IS_DEBUG_ENCLAVE ${IS_DEBUG_ENCLAVE} \
        --arg IBC_ADDRESS ${IBC_ADDRESS} \
        --arg LC_ADDRESS ${LC_ADDRESS} \
        --arg RISC0_IMAGE_ID ${LCP_RISC0_IMAGE_ID} \
        -f ${TEMPLATE_DIR}/ibc-1-zkdcap.json.tpl > ${CONFIG_DIR}/ibc-1.json
else
    jq -n \
        --arg MRENCLAVE ${LCP_MRENCLAVE} \
        --argjson IS_DEBUG_ENCLAVE ${IS_DEBUG_ENCLAVE} \
        --arg LC_ADDRESS ${LC_ADDRESS} \
        -f ${TEMPLATE_DIR}/ibc-0.json.tpl > ${CONFIG_DIR}/ibc-0.json

    jq -n \
        --arg MRENCLAVE ${LCP_MRENCLAVE} \
        --argjson IS_DEBUG_ENCLAVE ${IS_DEBUG_ENCLAVE} \
        --arg IBC_ADDRESS ${IBC_ADDRESS} \
        --arg LC_ADDRESS ${LC_ADDRESS} \
        -f ${TEMPLATE_DIR}/ibc-1.json.tpl > ${CONFIG_DIR}/ibc-1.json
fi

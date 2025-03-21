#!/bin/sh
set -ex

IS_DEBUG_ENCLAVE=false
if [ "$LCP_ENCLAVE_DEBUG" = "1" ]; then
    IS_DEBUG_ENCLAVE=true
fi
if [ -z "$LCP_KEY_EXPIRATION" ]; then
    echo "LCP_KEY_EXPIRATION is not set"
    exit 1
fi
# set LCP_ZKDCAP_RISC0_MOCK as false if not set
if [ -z "$LCP_ZKDCAP_RISC0_MOCK" ]; then
    LCP_ZKDCAP_RISC0_MOCK=false
fi

TEMPLATE_DIR=${E2E_TEST_DIR}/configs/templates
CONFIG_DIR=${E2E_TEST_DIR}/configs/demo

ADDRESSES_DIR=./tests/e2e/chains/ethereum/contracts/addresses

IBC_ADDRESS=$(cat $ADDRESSES_DIR/IBCHandler)
LC_ADDRESS=$(cat $ADDRESSES_DIR/LCPClient)

mkdir -p $CONFIG_DIR
if [ "$ZKDCAP" = true ]; then
    if [ -z "$LCP_RISC0_IMAGE_ID" ]; then
        echo "LCP_RISC0_IMAGE_ID is not set"
        exit 1
    fi

    jq -n \
        --arg MRENCLAVE ${LCP_MRENCLAVE} \
        --argjson IS_DEBUG_ENCLAVE ${IS_DEBUG_ENCLAVE} \
        --argjson LCP_KEY_EXPIRATION ${LCP_KEY_EXPIRATION} \
        --arg LC_ADDRESS ${LC_ADDRESS} \
        --arg RISC0_IMAGE_ID ${LCP_RISC0_IMAGE_ID} \
        --argjson LCP_ZKDCAP_RISC0_MOCK ${LCP_ZKDCAP_RISC0_MOCK} \
        -f ${TEMPLATE_DIR}/ibc-0-zkdcap.json.tpl > ${CONFIG_DIR}/ibc-0.json

    jq -n \
        --arg MRENCLAVE ${LCP_MRENCLAVE} \
        --argjson IS_DEBUG_ENCLAVE ${IS_DEBUG_ENCLAVE} \
        --argjson LCP_KEY_EXPIRATION ${LCP_KEY_EXPIRATION} \
        --arg IBC_ADDRESS ${IBC_ADDRESS} \
        --arg LC_ADDRESS ${LC_ADDRESS} \
        --arg RISC0_IMAGE_ID ${LCP_RISC0_IMAGE_ID} \
        --argjson LCP_ZKDCAP_RISC0_MOCK ${LCP_ZKDCAP_RISC0_MOCK} \
        -f ${TEMPLATE_DIR}/ibc-1-zkdcap.json.tpl > ${CONFIG_DIR}/ibc-1.json
else
    jq -n \
        --arg MRENCLAVE ${LCP_MRENCLAVE} \
        --argjson IS_DEBUG_ENCLAVE ${IS_DEBUG_ENCLAVE} \
        --argjson LCP_KEY_EXPIRATION ${LCP_KEY_EXPIRATION} \
        --arg LC_ADDRESS ${LC_ADDRESS} \
        -f ${TEMPLATE_DIR}/ibc-0.json.tpl > ${CONFIG_DIR}/ibc-0.json

    jq -n \
        --arg MRENCLAVE ${LCP_MRENCLAVE} \
        --argjson IS_DEBUG_ENCLAVE ${IS_DEBUG_ENCLAVE} \
        --argjson LCP_KEY_EXPIRATION ${LCP_KEY_EXPIRATION} \
        --arg IBC_ADDRESS ${IBC_ADDRESS} \
        --arg LC_ADDRESS ${LC_ADDRESS} \
        -f ${TEMPLATE_DIR}/ibc-1.json.tpl > ${CONFIG_DIR}/ibc-1.json
fi

#!/bin/sh
set -eux
LCP_BIN=${LCP_BIN:-lcp}
TEMPLATE_DIR=./tests/e2e/cases/xion2xion/configs/templates
CONFIG_DIR=./tests/e2e/cases/xion2xion/configs/demo
mkdir -p $CONFIG_DIR
MRENCLAVE=$(${LCP_BIN} enclave metadata --enclave=./bin/enclave.signed.so | jq -r .mrenclave)
WASM_CODE_CHECKSUM=$(sha256sum $WASM_CODE | sed 's/ .*//' | xxd -r -p | base64)
jq -n -f ${TEMPLATE_DIR}/ibc-0.json.tpl --arg WASM_CODE_CHECKSUM ${WASM_CODE_CHECKSUM} > ${CONFIG_DIR}/ibc-0.json
jq -n -f ${TEMPLATE_DIR}/ibc-1.json.tpl --arg MRENCLAVE ${MRENCLAVE} > ${CONFIG_DIR}/ibc-1.json

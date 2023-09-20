#!/bin/sh
set -eux
LCP_BIN=${LCP_BIN:-lcp}
TEMPLATE_DIR=./tests/e2e/cases/tm2eth/configs/templates
CONFIG_DIR=./tests/e2e/cases/tm2eth/configs/demo
mkdir -p $CONFIG_DIR
MRENCLAVE=$(${LCP_BIN} enclave metadata --enclave=./bin/enclave.signed.so | jq -r .mrenclave)
jq --arg MRENCLAVE ${MRENCLAVE} -r '.prover.mrenclave = $MRENCLAVE' ${TEMPLATE_DIR}/ibc-0.json.tpl > ${CONFIG_DIR}/ibc-0.json
jq --arg MRENCLAVE ${MRENCLAVE} -r '.prover.mrenclave = $MRENCLAVE' ${TEMPLATE_DIR}/ibc-1.json.tpl > ${CONFIG_DIR}/ibc-1.json

#!/bin/sh
set -eux
LCP_BIN=${LCP_BIN:-lcp}
TEMPLATE_DIR=./tests/e2e/cases/tm2eth/configs/templates
CONFIG_DIR=./tests/e2e/cases/tm2eth/configs/demo
ADDRESSES_DIR=./tests/e2e/chains/ethereum/contracts/addresses
mkdir -p $CONFIG_DIR
MRENCLAVE=$(${LCP_BIN} enclave metadata --enclave=./bin/enclave.signed.so | jq -r .mrenclave)
IBC_ADDRESS=`cat $ADDRESSES_DIR/IBCHandler`
LC_ADDRESS=`cat $ADDRESSES_DIR/LCPClient`
jq -n -f ${TEMPLATE_DIR}/ibc-0.json.tpl --arg MRENCLAVE ${MRENCLAVE} --arg LC_ADDRESS $LC_ADDRESS > ${CONFIG_DIR}/ibc-0.json
jq -n -f ${TEMPLATE_DIR}/ibc-1.json.tpl --arg MRENCLAVE ${MRENCLAVE} --arg IBC_ADDRESS ${IBC_ADDRESS} --arg LC_ADDRESS $LC_ADDRESS > ${CONFIG_DIR}/ibc-1.json

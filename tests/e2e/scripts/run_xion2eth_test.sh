#!/usr/bin/env bash
set -ex

source $(cd $(dirname "$0"); pwd)/util

export LCP_ENCLAVE_DEBUG=1

ENCLAVE_PATH=./bin/enclave.signed.so
LCP_BIN=${LCP_BIN:-lcp}
CERTS_DIR=./tests/certs

./tests/e2e/scripts/init_lcp.sh

if [ "$SGX_MODE" = "SW" ]; then
    export LCP_RA_ROOT_CERT_HEX=$(cat ${CERTS_DIR}/root.crt | xxd -p -c 1000000)
fi

${LCP_BIN} --log_level=info service start --enclave=${ENCLAVE_PATH} --address=127.0.0.1:50051 --threads=2 &
LCP_PID=$!

make -C tests/e2e/cases/xion2eth network
# wait until first finality_update is built
retry 20 curl -fsL http://localhost:19596/eth/v1/beacon/light_client/finality_update -o /dev/null -w '%{http_code}\n'

./tests/e2e/cases/xion2eth/scripts/gen_rly_config.sh

make -C tests/e2e/cases/xion2eth setup

RLY_BIN=bin/yrly ./tests/e2e/cases/xion2eth/scripts/store_wasm_code.sh

make -C tests/e2e/cases/xion2eth handshake

if [ $USE_UPGRADE_TEST = yes ]
then
    make -C tests/e2e/cases/xion2eth test-channel-upgrade
fi

# test for restore ELC state
kill $LCP_PID
./tests/e2e/scripts/init_lcp.sh
${LCP_BIN} --log_level=info service start --enclave=${ENCLAVE_PATH} --address=127.0.0.1:50051 --threads=2 &
LCP_PID=$!
make -C tests/e2e/cases/xion2eth restore

make -C tests/e2e/cases/xion2eth test
make -C tests/e2e/cases/xion2eth test-operators
make -C tests/e2e/cases/xion2eth network-down
kill $LCP_PID

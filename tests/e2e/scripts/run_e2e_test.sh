#!/usr/bin/env bash
set -ex

source $(cd $(dirname "$0"); pwd)/util

ENCLAVE_PATH=./bin/enclave.signed.so
LCP_BIN=${LCP_BIN:-lcp}
CERTS_DIR=./tests/certs

./tests/e2e/scripts/init_lcp.sh

if [ "$SGX_MODE" = "SW" ]; then
    export LCP_RA_ROOT_CERT_HEX=$(cat ${CERTS_DIR}/root.crt | xxd -p -c 1000000)
fi

./tests/e2e/cases/tm2eth/scripts/gen_rly_config.sh

${LCP_BIN} --log_level=info service start --enclave=${ENCLAVE_PATH} --address=127.0.0.1:50051 --threads=2 &
LCP_PID=$!

make -C tests/e2e/cases/tm2eth network
# wait until first finality_update is built
retry 20 curl -fsL http://localhost:19596/eth/v1/beacon/light_client/finality_update -o /dev/null -w '%{http_code}\n'

make -C tests/e2e/cases/tm2eth setup handshake

# test for restore ELC state
kill $LCP_PID
./tests/e2e/scripts/init_lcp.sh
${LCP_BIN} --log_level=info service start --enclave=${ENCLAVE_PATH} --address=127.0.0.1:50051 --threads=2 &
LCP_PID=$!
make -C tests/e2e/cases/tm2eth restore

make -C tests/e2e/cases/tm2eth test
make -C tests/e2e/cases/tm2eth network-down
kill $LCP_PID

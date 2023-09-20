#!/usr/bin/env bash
set -ex

source $(cd $(dirname "$0"); pwd)/util

ENCLAVE_PATH=./bin/enclave.signed.so
LCP_BIN=${LCP_BIN:-lcp}

rm -rf ~/.lcp

enclave_key=$(${LCP_BIN} --log_level=off enclave generate-key --enclave=${ENCLAVE_PATH})
./tests/e2e/cases/tm2eth/scripts/gen_rly_config.sh

if [ -z "$SGX_MODE" -o "$SGX_MODE" = "HW" ]; then
    ${LCP_BIN} attestation ias --enclave=${ENCLAVE_PATH} --enclave_key=${enclave_key}
else
    ${LCP_BIN} attestation simulate --enclave=${ENCLAVE_PATH} --enclave_key=${enclave_key} --signing_cert_path=./tests/certs/signing.crt.der --signing_key=./tests/certs/signing.key
    export LCP_RA_ROOT_CERT_HEX=$(cat ./tests/certs/root.crt | xxd -p -c 1000000)
fi

${LCP_BIN} --log_level=info service start --enclave=${ENCLAVE_PATH} --address=127.0.0.1:50051 --threads=2 &
LCP_PID=$!

make -C tests/e2e/cases/tm2eth network
# wait until first finality_update is built
retry 20 curl -fsL http://localhost:19596/eth/v1/beacon/light_client/finality_update -o /dev/null -w '%{http_code}\n'
make -C tests/e2e/cases/tm2eth test
make -C tests/e2e/cases/tm2eth network-down
kill $LCP_PID

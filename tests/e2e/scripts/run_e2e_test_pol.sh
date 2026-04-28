#!/usr/bin/env bash
set -ex

# Phase 1 smoke driver for the tm2pol case.
# Brings up the kurtosis-pos devnet, starts LCP, generates relayer config, and runs
# `lcp create-elc` + `lcp update-elc` against the Polygon ELC. No handshake, no
# tendermint chain, no contract deploy.

source $(cd $(dirname "$0"); pwd)/util

E2E_TEST_DIR=./tests/e2e/cases/tm2pol

export NO_RUN_LCP=${NO_RUN_LCP:-false}
export LCP_ENCLAVE_DEBUG=${LCP_ENCLAVE_DEBUG:-1}
export LCP_KEY_EXPIRATION=${LCP_KEY_EXPIRATION:-86400}
export ZKDCAP=${ZKDCAP:-false}
export LCP_ZKDCAP_RISC0_MOCK=${LCP_ZKDCAP_RISC0_MOCK:-false}

CERTS_DIR=./tests/certs

if [ "$NO_RUN_LCP" = "false" ]; then
    LCP_BIN=${LCP_BIN:-./bin/lcp}
    LCP_ENCLAVE_PATH=${LCP_ENCLAVE_PATH:-./bin/enclave.signed.so}
    export LCP_MRENCLAVE=$(${LCP_BIN} enclave metadata --enclave=${LCP_ENCLAVE_PATH} | jq -r .mrenclave)
    LCP_BIN=${LCP_BIN} LCP_ENCLAVE_PATH=${LCP_ENCLAVE_PATH} ./tests/e2e/scripts/init_lcp.sh
    ${LCP_BIN} --log_level=info service start --enclave=${LCP_ENCLAVE_PATH} --address=127.0.0.1:50051 --threads=2 &
    LCP_PID=$!
    if [ "$SGX_MODE" = "SW" ]; then
        export LCP_RA_ROOT_CERT_HEX=$(cat ${CERTS_DIR}/root.crt | xxd -p -c 1000000)
        export LCP_DCAP_RA_ROOT_CERT_HEX=$(cat ${CERTS_DIR}/simulate_dcap_root_cert.pem | xxd -p -c 1000000)
    fi
else
    res=$(grpcurl -plaintext 127.0.0.1:50051 lcp.service.enclave.v1.Query.EnclaveInfo)
    export LCP_MRENCLAVE=0x$(echo $res | jq -r .mrenclave | base64 -d | xxd -p | tr -d $'\n')
fi

make -C ${E2E_TEST_DIR} network

# wait for first heimdall block (CometBFT RPC reachable + height > 0)
HEIMDALL_RPC=$(make -s -C ./tests/e2e/chains/polygon heimdall-cometbft-url)
retry 60 sh -c "curl -fsL ${HEIMDALL_RPC}/status -o /dev/null"

E2E_TEST_DIR=${E2E_TEST_DIR} ${E2E_TEST_DIR}/scripts/gen_rly_config.sh
make -C ${E2E_TEST_DIR} setup test

if [ "$NO_RUN_LCP" = "false" ]; then
    kill $LCP_PID || true
fi

make -C ${E2E_TEST_DIR} network-down

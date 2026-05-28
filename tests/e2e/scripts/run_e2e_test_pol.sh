#!/usr/bin/env bash
set -ex

# Phase 2b driver for the tm2pol case.
# Brings up LCP + cosmos (ibc0) + Polygon PoS via kurtosis (ibc1), deploys
# ibc-solidity + LCPClientIAS + AppV1 to bor, generates the relayer config,
# runs handshake (clients + connection + channel), then exercises bidirectional
# packet relay (test-tx + test-service). test-operators / channel upgrade are
# deferred to Phase 2c.

source $(cd $(dirname "$0"); pwd)/util

E2E_TEST_DIR=./tests/e2e/cases/tm2pol

export NO_RUN_LCP=${NO_RUN_LCP:-false}
export LCP_ENCLAVE_DEBUG=${LCP_ENCLAVE_DEBUG:-1}
export LCP_KEY_EXPIRATION=${LCP_KEY_EXPIRATION:-86400}
export ZKDCAP=${ZKDCAP:-false}
export LCP_ZKDCAP_RISC0_MOCK=${LCP_ZKDCAP_RISC0_MOCK:-false}

CERTS_DIR=./tests/certs

LCP_PID=

# If a previous run failed mid-handshake (set -e exits before the cleanup
# block), the lcp service process is left bound to :50051. A new `lcp service
# start` then silently fails to bind and the next gRPC calls hit the stale
# service holding ELC state from the previous run's chain — manifesting as
# `no available updates` because the stale ELC is ahead of the fresh chain.
# Reap any stragglers up-front.
pkill -f 'lcp.*service start' 2>/dev/null || true

cleanup() {
    if [ -n "${LCP_PID}" ]; then
        kill ${LCP_PID} 2>/dev/null || true
    fi
}
trap cleanup EXIT

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

# Tendermint + kurtosis-pos devnet + polygon contract deploy + ABI extract.
make -C ${E2E_TEST_DIR} network

# Wait for heimdall RPC. Pass curl args individually — `retry` joins $@ with
# $IFS and re-word-splits, so any quoted "sh -c ..." form gets shredded.
HEIMDALL_RPC=$(make -s -C ./tests/e2e/chains/polygon heimdall-cometbft-url)
retry 60 curl -fsL "${HEIMDALL_RPC}/status" -o /dev/null

make -C ${E2E_TEST_DIR} setup handshake test

make -C ${E2E_TEST_DIR} network-down

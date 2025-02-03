#!/usr/bin/env bash
set -ex

# Usage: run_e2e_test.sh <--no_run_lcp> <--zkdcap>

source $(cd $(dirname "$0"); pwd)/util

E2E_TEST_DIR=./tests/e2e/cases/tm2eth
OPERATORS_ENABLED=false
NO_RUN_LCP=false
ZKDCAP=false
CERTS_DIR=./tests/certs
ARGS=$(getopt -o '' --long no_run_lcp,zkdcap -n 'parse-options' -- "$@")
eval set -- "$ARGS"
while true; do
    case "$1" in
        --no_run_lcp)
            echo "Skip running LCP"
            if [ "$LCP_MRENCLAVE" = "" ]; then
                echo "LCP_MRENCLAVE is not set"
                exit 1
            fi
            NO_RUN_LCP=true
            shift
            ;;
        --zkdcap)
            echo "ZKDCAP enabled"
            ZKDCAP=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal error!"
            exit 1
            ;;
    esac
done

if [ "$NO_RUN_LCP" = "false" ]; then
    echo "Run LCP for testing"
    LCP_BIN=${LCP_BIN:-./bin/lcp}
    LCP_ENCLAVE_PATH=${LCP_ENCLAVE_PATH:-./bin/enclave.signed.so}
    export LCP_ENCLAVE_DEBUG=1
    export LCP_MRENCLAVE=$(${LCP_BIN} enclave metadata --enclave=${LCP_ENCLAVE_PATH} | jq -r .mrenclave)
    LCP_BIN=${LCP_BIN} LCP_ENCLAVE_PATH=${LCP_ENCLAVE_PATH} ./tests/e2e/scripts/init_lcp.sh
    ${LCP_BIN} --log_level=info service start --enclave=${LCP_ENCLAVE_PATH} --address=127.0.0.1:50051 --threads=2 &
    LCP_PID=$!
    if [ "$SGX_MODE" = "SW" ]; then
        export LCP_RA_ROOT_CERT_HEX=$(cat ${CERTS_DIR}/root.crt | xxd -p -c 1000000)
    fi
else
    echo "Skip running LCP"
    echo "We assume that LCP is running with the HW mode"
    if [ "$LCP_MRENCLAVE" = "" ]; then
        echo "LCP_MRENCLAVE is not set"
        exit 1
    fi
    if [ "$SGX_MODE" = "SW" ]; then
        echo "Override the SGX_MODE to HW"
        export SGX_MODE=HW
    fi
fi

ZKDCAP=${ZKDCAP} make -C ${E2E_TEST_DIR} network

ZKDCAP=${ZKDCAP} E2E_TEST_DIR=${E2E_TEST_DIR} ${E2E_TEST_DIR}/scripts/gen_rly_config.sh

# wait until first finality_update is built
retry 20 curl -fsL http://localhost:19596/eth/v1/beacon/light_client/finality_update -o /dev/null -w '%{http_code}\n'
make -C ${E2E_TEST_DIR} setup handshake

if [ $USE_UPGRADE_TEST = yes ]
then
    make -C ${E2E_TEST_DIR} test-channel-upgrade
fi

if [ "$ZKDCAP" = "false" ] && [ "$NO_RUN_LCP" = "false" ]; then
    echo "Shutdown LCP for testing restore ELC state"
    kill $LCP_PID
    ./tests/e2e/scripts/init_lcp.sh
    ${LCP_BIN} --log_level=info service start --enclave=${LCP_ENCLAVE_PATH} --address=127.0.0.1:50051 --threads=2 &
    LCP_PID=$!
    echo "Restore ELC state"
    make -C ${E2E_TEST_DIR} restore
fi

make -C ${E2E_TEST_DIR} test
make -C ${E2E_TEST_DIR} test-operators
make -C ${E2E_TEST_DIR} network-down
if [ "$NO_RUN_LCP" = false ]; then
    kill $LCP_PID
fi

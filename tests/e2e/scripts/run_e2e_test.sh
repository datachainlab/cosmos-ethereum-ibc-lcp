#!/usr/bin/env bash
set -ex

# Usage: run_e2e_test.sh <--no_run_lcp> <--zkdcap|--mock_zkdcap> <--enclave_debug> <--upgrade_test> <--key_expiration=<integer>>

source $(cd $(dirname "$0"); pwd)/util

E2E_TEST_DIR=./tests/e2e/cases/tm2eth

export NO_RUN_LCP=false
export LCP_ENCLAVE_DEBUG=0
export LCP_KEY_EXPIRATION=86400
# LCP_RISC0_IMAGE_ID must be set to the same value as in the LCP service
# e.g. https://github.com/datachainlab/zkdcap/blob/fd44cfc9718a0bd4a58f5dbf2b0b89c25144893d/zkvm/risc0/src/methods.rs#L3
LCP_RISC0_IMAGE_ID=${LCP_RISC0_IMAGE_ID:-0xe5056aa7a8064abeb648b31d5efa8697a79d416b937cb917d1428cec91a56c67}
export ZKDCAP=false
export LCP_ZKDCAP_RISC0_MOCK=false
export LCP_RISC0_IMAGE_ID
export USE_UPGRADE_TEST=no
USE_FAKELOST_TEST=no
USE_SHFU_SERVER=no

CERTS_DIR=./tests/certs
ARGS=$(getopt -o '' --long no_run_lcp,enclave_debug,zkdcap,mock_zkdcap,upgrade_test,fakelost_test,shfu_server,key_expiration: -- "$@")
eval set -- "$ARGS"
while true; do
    case "$1" in
        --no_run_lcp)
            echo "Skip running LCP"
            NO_RUN_LCP=true
            shift
            ;;
        --enclave_debug)
            echo "Enclave debug enabled"
            LCP_ENCLAVE_DEBUG=1
            shift
            ;;
        --zkdcap)
            echo "ZKDCAP enabled"
            ZKDCAP=true
            LCP_ZKDCAP_RISC0_MOCK=false
            shift
            ;;
        --mock_zkdcap)
            echo "Mock ZKDCAP enabled"
            ZKDCAP=true
            LCP_ZKDCAP_RISC0_MOCK=true
            shift
            ;;
        --key_expiration)
            echo "Key expiration set to $2"
            LCP_KEY_EXPIRATION=$2
            shift 2
            ;;
        --upgrade_test)
            echo "Enable upgrade test"
            USE_UPGRADE_TEST=yes
            shift
            ;;
        --fakelost_test)
            echo "Enable fakelost test"
            USE_FAKELOST_TEST=yes
            shift
            ;;
        --shfu_server)
            echo "Enable SHFU server"
            USE_SHFU_SERVER=yes
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

MAKE_TEST_ARG="${MAKE_TEST_ARG} USE_FAKELOST_TEST=${USE_FAKELOST_TEST}"

if [ "$NO_RUN_LCP" = "false" ]; then
    echo "Run LCP for testing"
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
    echo "Skip running LCP"
    echo "We assume that LCP is running with the HW mode"
    res=$(grpcurl -plaintext 127.0.0.1:50051 lcp.service.enclave.v1.Query.EnclaveInfo)
    enclave_debug=$(echo $res | jq -r .enclaveDebug)
    if [ "$enclave_debug" == "true" ]; then
        if [ "$LCP_ENCLAVE_DEBUG" == "0" ]; then
            echo "Remote LCP's enclave debug is enabled, but LCP_ENCLAVE_DEBUG is not set"
            exit 1
        fi
    else
        if [ "$LCP_ENCLAVE_DEBUG" == "1" ]; then
            echo "Remote LCP's enclave debug is disabled, but LCP_ENCLAVE_DEBUG is set"
            exit 1
        fi
    fi
    export LCP_MRENCLAVE=0x$(echo $res | jq -r .mrenclave | base64 -d | xxd -p | tr -d $'\n')
fi

make -C ${E2E_TEST_DIR} ${MAKE_TEST_ARG} network

E2E_TEST_DIR=${E2E_TEST_DIR} ${E2E_TEST_DIR}/scripts/gen_rly_config.sh

# wait until first finality_update is built
retry 20 curl -fsL http://localhost:19596/eth/v1/beacon/light_client/finality_update -o /dev/null -w '%{http_code}\n'
make -C ${E2E_TEST_DIR} ${MAKE_TEST_ARG} setup handshake

if [ $USE_UPGRADE_TEST = yes ]
then
    make -C ${E2E_TEST_DIR} ${MAKE_TEST_ARG} test-channel-upgrade
fi

if [ "$NO_RUN_LCP" = "false" ]; then
    echo "Shutdown LCP for testing restore ELC state"
    kill $LCP_PID
    ./tests/e2e/scripts/init_lcp.sh
    echo "Restart LCP"
    ${LCP_BIN} --log_level=info service start --enclave=${LCP_ENCLAVE_PATH} --address=127.0.0.1:50051 --threads=2 &
    LCP_PID=$!
    echo "Restore ELC state"
    make -C ${E2E_TEST_DIR} restore
fi

make -C ${E2E_TEST_DIR} ${MAKE_TEST_ARG} test

if [ ${USE_SHFU_SERVER} = "yes" ]; then
    make -C ${E2E_TEST_DIR} ${MAKE_TEST_ARG} shfu-server-start
    make -C ${E2E_TEST_DIR} ${MAKE_TEST_ARG} ENABLE_SHFU_GRPC=yes test
    make -C ${E2E_TEST_DIR} ${MAKE_TEST_ARG} shfu-server-stop
fi

make -C ${E2E_TEST_DIR} ${MAKE_TEST_ARG} test-operators

make -C ${E2E_TEST_DIR} ${MAKE_TEST_ARG} network-down
if [ "$NO_RUN_LCP" = false ]; then
    kill $LCP_PID
fi

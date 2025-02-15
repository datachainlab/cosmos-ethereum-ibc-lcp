#!/bin/sh
set -ex

LCP_BIN=${LCP_BIN:-./bin/lcp}
LCP_ENCLAVE_PATH=${LCP_ENCLAVE_PATH:-./bin/enclave.signed.so}

CERTS_DIR=./lcp/tests/certs

echo "Generate LCP configuration"
echo "Remove existing LCP configuration"
rm -rf ~/.lcp

echo "Create new LCP configuration ZKDCAP=${ZKDCAP} SGX_MODE=${SGX_MODE} LCP_ENCLAVE_DEBUG=${LCP_ENCLAVE_DEBUG}"

if [ "$ZKDCAP" = "true" ] && [ "$SGX_MODE" != "SW" ]; then
    ${LCP_BIN} attestation zkdcap --enclave=${LCP_ENCLAVE_PATH} --prove_mode=local \
        --enclave_key=$(${LCP_BIN} --log_level=off enclave generate-key --enclave=${LCP_ENCLAVE_PATH} --target_qe=qe3)
elif [ "$ZKDCAP" = "true" ]; then
    if [ "$LCP_ZKDCAP_RISC0_MOCK" = "true" ]; then
        prove_mode=dev
    elif [ -n "$BONSAI_API_KEY" ]; then
        prove_mode=bonsai
    else
        prove_mode=local
    fi
    ${LCP_BIN} attestation zkdcap-sim --enclave=${LCP_ENCLAVE_PATH} --prove_mode=${prove_mode} \
        --enclave_key=$(${LCP_BIN} --log_level=off enclave generate-key --enclave=${LCP_ENCLAVE_PATH} --target_qe=qe3sim)
elif [ -z "$SGX_MODE" ] || [ "$SGX_MODE" = "HW" ]; then
    ${LCP_BIN} attestation ias --enclave=${LCP_ENCLAVE_PATH} \
        --enclave_key=$(${LCP_BIN} --log_level=off enclave generate-key --enclave=${LCP_ENCLAVE_PATH} --target_qe=qe)
else
    ${LCP_BIN} attestation simulate --enclave=${LCP_ENCLAVE_PATH} --signing_cert_path=${CERTS_DIR}/signing.crt.der --signing_key=${CERTS_DIR}/signing.key \
        --enclave_key=$(${LCP_BIN} --log_level=off enclave generate-key --enclave=${LCP_ENCLAVE_PATH} --target_qe=qe)
fi

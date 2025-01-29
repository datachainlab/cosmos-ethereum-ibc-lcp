#!/bin/sh
set -ex

LCP_BIN=${LCP_BIN:-./bin/lcp}
LCP_ENCLAVE_PATH=${LCP_ENCLAVE_PATH:-./bin/enclave.signed.so}

CERTS_DIR=./lcp/tests/certs

echo "Generate LCP configuration"
echo "Remove existing LCP configuration"
rm -rf ~/.lcp

echo "Create new LCP configuration"
enclave_key=$(${LCP_BIN} --log_level=off enclave generate-key --enclave=${LCP_ENCLAVE_PATH})

if [ -z "$SGX_MODE" ] || [ "$SGX_MODE" = "HW" ]; then
    ${LCP_BIN} attestation ias --enclave=${LCP_ENCLAVE_PATH} --enclave_key=${enclave_key}
else
    ${LCP_BIN} attestation simulate --enclave=${LCP_ENCLAVE_PATH} --enclave_key=${enclave_key} --signing_cert_path=${CERTS_DIR}/signing.crt.der --signing_key=${CERTS_DIR}/signing.key
fi

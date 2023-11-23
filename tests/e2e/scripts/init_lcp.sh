#!/bin/sh
set -ex

LCP_BIN=${LCP_BIN:-lcp}
ENCLAVE_PATH=./bin/enclave.signed.so
CERTS_DIR=./tests/certs

rm -rf ~/.lcp

enclave_key=$(${LCP_BIN} --log_level=off enclave generate-key --enclave=${ENCLAVE_PATH})

if [ -z "$SGX_MODE" ] || [ "$SGX_MODE" = "HW" ]; then
    ${LCP_BIN} attestation ias --enclave=${ENCLAVE_PATH} --enclave_key=${enclave_key}
else
    ${LCP_BIN} attestation simulate --enclave=${ENCLAVE_PATH} --enclave_key=${enclave_key} --signing_cert_path=${CERTS_DIR}/signing.crt.der --signing_key=${CERTS_DIR}/signing.key
fi

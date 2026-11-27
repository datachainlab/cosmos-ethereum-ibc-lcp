######## SGX SDK Settings ########
SGX_SDK ?= /opt/sgxsdk
SGX_MODE ?= HW
SGX_ARCH ?= x64
SGX_DEBUG ?= 0
SGX_PRERELEASE ?= 0
SGX_PRODUCTION ?= 0

include buildenv.mk

ifeq ($(shell getconf LONG_BIT), 32)
	SGX_ARCH := x86
else ifeq ($(findstring -m32, $(CXXFLAGS)), -m32)
	SGX_ARCH := x86
endif

ifeq ($(SGX_ARCH), x86)
	SGX_ENCLAVE_SIGNER := $(SGX_SDK)/bin/x86/sgx_sign
else
	SGX_ENCLAVE_SIGNER := $(SGX_SDK)/bin/x64/sgx_sign
endif

ifeq ($(SGX_DEBUG), 1)
ifeq ($(SGX_PRERELEASE), 1)
$(error Cannot set SGX_DEBUG and SGX_PRERELEASE at the same time!!)
endif
ifeq ($(SGX_PRODUCTION), 1)
$(error Cannot set SGX_DEBUG and SGX_PRODUCTION at the same time!!)
endif
endif

ifeq ($(SGX_DEBUG), 1)
	# we build with cargo --release, even in SGX DEBUG mode
	# cargo sets this automatically, cannot use 'debug'
	OUTPUT_PATH := release
	CARGO_TARGET := --release
else
	OUTPUT_PATH := release
	CARGO_TARGET := --release
endif

ENCLAVE_CARGO_FEATURES = --features=default
APP_CARGO_FEATURES     = --features=default
ifeq ($(SGX_PRODUCTION), 1)
	SGX_ENCLAVE_MODE = "Production Mode"
	SGX_ENCLAVE_CONFIG = $(SGX_ENCLAVE_CONFIG)
	SGX_SIGN_KEY = $(SGX_COMMERCIAL_KEY)
else
	SGX_ENCLAVE_MODE = "Development Mode"
	SGX_ENCLAVE_CONFIG = "enclave/Enclave.config.xml"
	SGX_SIGN_KEY = "enclave/Enclave_private.pem"
	ifneq ($(SGX_MODE), HW)
		ENCLAVE_CARGO_FEATURES = --features=default
		APP_CARGO_FEATURES     = --features=default,sgx-sw
	endif
endif

######## CUSTOM Settings ########

CUSTOM_BIN_PATH := ./bin

######## Enclave Settings ########

Enclave_Target_Spec := $(CURDIR)/lcp/enclave/x86_64-unknown-unknown-sgx.json

RustEnclave_Name := enclave/target/x86_64-unknown-unknown-sgx/$(OUTPUT_PATH)/enclave.so
Signed_RustEnclave_Name := bin/enclave.signed.so

######## Test Settings ########

.PHONY: all
all: $(Signed_RustEnclave_Name)

######## Enclave Objects ########

$(Signed_RustEnclave_Name): enclave
	mkdir -p bin
	@$(SGX_ENCLAVE_SIGNER) sign -key enclave/Enclave_private.pem -enclave $(RustEnclave_Name) -out $@ -config enclave/Enclave.config.xml
	@echo "SIGN =>  $@"

CARGO_SGX_TAG := v0.1.0

.PHONY: enclave-tools
enclave-tools:
	@rustup component add rust-src
	@command -v cargo-sgx >/dev/null 2>&1 || \
		cargo install --git https://github.com/datachainlab/sgx-sdk-rs --tag $(CARGO_SGX_TAG) cargo-sgx --locked

.PHONY: enclave
enclave: enclave-tools
	@cd enclave && SGX_SDK=$(SGX_SDK) SGX_MODE=$(SGX_MODE) BLST_TEST_NO_STD=yes \
		CARGO_UNSTABLE_BUILD_STD=core,alloc \
		cargo sgx build --target $(Enclave_Target_Spec) $(CARGO_TARGET)

.PHONY: clean
clean:
	@rm -f $(RustEnclave_Name) $(Signed_RustEnclave_Name)
	@cd enclave && cargo clean

.PHONY: fmt
fmt:
	@cargo fmt --all && cd ./enclave && cargo fmt --all

.PHONY: yrly
yrly:
	go build -o ./bin/yrly -tags customcert,ylry_debug ./relayer

######## E2E test ########

LCP_REPO=./lcp
LCP_BIN=$(LCP_REPO)/bin/lcp

E2E_OPTIONS=""

$(LCP_BIN):
	$(MAKE) -C $(LCP_REPO)

.PHONY: prepare-contracts
prepare-contracts:
	$(MAKE) -C ./tests/e2e/chains/ethereum dep

.PHONY: build-images
build-images:
	$(MAKE) -C ./tests/e2e/chains/tendermint image
	$(MAKE) -C ./tests/e2e/chains/ethereum build-images

.PHONY: e2e-test
e2e-test: e2e-clean $(LCP_BIN) $(Signed_RustEnclave_Name) yrly
	LCP_BIN=$(LCP_BIN) ./tests/e2e/scripts/run_e2e_test.sh $(E2E_OPTIONS)

.PHONY: e2e-clean
e2e-clean:
	$(MAKE) -C ./tests/e2e/chains/ethereum rm-oz-upgrades

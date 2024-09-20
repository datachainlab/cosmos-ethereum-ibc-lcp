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
	SGX_COMMON_CFLAGS := -m32
	SGX_LIBRARY_PATH := $(SGX_SDK)/lib
	SGX_ENCLAVE_SIGNER := $(SGX_SDK)/bin/x86/sgx_sign
	SGX_EDGER8R := $(SGX_SDK)/bin/x86/sgx_edger8r
else
	SGX_COMMON_CFLAGS := -m64
	SGX_LIBRARY_PATH := $(SGX_SDK)/lib64
	SGX_ENCLAVE_SIGNER := $(SGX_SDK)/bin/x64/sgx_sign
	SGX_EDGER8R := $(SGX_SDK)/bin/x64/sgx_edger8r
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
	SGX_COMMON_CFLAGS += -O0 -g -ggdb
	# cargo sets this automatically, cannot use 'debug'
	OUTPUT_PATH := release
	CARGO_TARGET := --release
else
	SGX_COMMON_CFLAGS += -O2
	OUTPUT_PATH := release
	CARGO_TARGET := --release
endif

SGX_COMMON_CFLAGS += -fstack-protector

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

CUSTOM_LIBRARY_PATH := ./lib
CUSTOM_BIN_PATH := ./bin

######## EDL Settings ########

Enclave_EDL_Files := enclave/Enclave_t.c enclave/Enclave_t.h app/Enclave_u.c app/Enclave_u.h

######## Enclave Settings ########

ifneq ($(SGX_MODE), HW)
	Trts_Library_Name := sgx_trts_sim
	Service_Library_Name := sgx_tservice_sim
else
	Trts_Library_Name := sgx_trts
	Service_Library_Name := sgx_tservice
endif
Crypto_Library_Name := sgx_tcrypto
ProtectedFs_Library_Name := sgx_tprotected_fs

RustEnclave_C_Files := $(wildcard ./enclave/*.c)
RustEnclave_C_Objects := $(RustEnclave_C_Files:.c=.o)
RustEnclave_Include_Paths := -I$(SGX_SDK)/include -I$(SGX_SDK)/include/tlibc -I$(SGX_SDK)/include/stlport -I$(SGX_SDK)/include/epid -I ./enclave -I./include

RustEnclave_Link_Libs := -L$(CUSTOM_LIBRARY_PATH) -lenclave
RustEnclave_Compile_Flags := $(SGX_COMMON_CFLAGS) $(ENCLAVE_CFLAGS) $(RustEnclave_Include_Paths)
RustEnclave_Link_Flags := -Wl,--no-undefined -nostdlib -nodefaultlibs -nostartfiles -L$(SGX_LIBRARY_PATH) \
	-Wl,--whole-archive -l$(Trts_Library_Name) -l${ProtectedFs_Library_Name} -Wl,--no-whole-archive \
	-Wl,--start-group -lsgx_tcxx -lsgx_tstdc -l$(Service_Library_Name) -l$(Crypto_Library_Name) $(RustEnclave_Link_Libs) -Wl,--end-group \
	-Wl,--version-script=enclave/Enclave.lds \
	$(ENCLAVE_LDFLAGS)
RUSTFLAGS :="-C target-feature=+avx2"

RustEnclave_Name := enclave/enclave.so
Signed_RustEnclave_Name := bin/enclave.signed.so

######## Test Settings ########

.PHONY: all
all: $(Signed_RustEnclave_Name)

######## EDL Objects ########

$(Enclave_EDL_Files): $(SGX_EDGER8R) enclave/Enclave.edl
	$(SGX_EDGER8R) --trusted enclave/Enclave.edl --search-path $(SGX_SDK)/include --trusted-dir enclave
	@echo "GEN  =>  $(Enclave_EDL_Files)"

######## Enclave Objects ########

enclave/Enclave_t.o: $(Enclave_EDL_Files)
	@$(CC) $(RustEnclave_Compile_Flags) -c enclave/Enclave_t.c -o $@
	@echo "CC   <=  $<"

$(RustEnclave_Name): enclave enclave/Enclave_t.o
	@$(CXX) enclave/Enclave_t.o -o $@ $(RustEnclave_Link_Flags)
	@echo "LINK =>  $@"

$(Signed_RustEnclave_Name): $(RustEnclave_Name)
	mkdir -p bin
	@$(SGX_ENCLAVE_SIGNER) sign -key enclave/Enclave_private.pem -enclave $(RustEnclave_Name) -out $@ -config enclave/Enclave.config.xml
	@echo "SIGN =>  $@"

.PHONY: enclave
enclave:
	@cd enclave && RUSTFLAGS=$(RUSTFLAGS) cargo build $(CARGO_TARGET) $(CARGO_FEATURES)
	@mkdir -p ./lib
	@cp enclave/target/$(OUTPUT_PATH)/libproxy_enclave.a ./lib/libenclave.a

.PHONY: clean
clean:
	@rm -f $(RustEnclave_Name) $(Signed_RustEnclave_Name) enclave/*_t.* lib/*.a
	@cd enclave && cargo clean && rm -f Cargo.lock

.PHONY: fmt
fmt:
	@cargo fmt --all && cd ./enclave && cargo fmt --all

.PHONY: docker
docker:
	@cd rust-sgx-sdk/dockerfile && docker build --no-cache -t datachainlab/sgx-rust:2004-1.1.5 -f Dockerfile.2004.nightly .

.PHONY: yrly
yrly:
	go build -o ./bin/yrly -tags customcert ./relayer

######## E2E test ########

LCP_BIN ?= lcp

.PHONY: prepare-contracts
prepare-contracts:
	make -C ./tests/e2e/chains/ethereum dep

.PHONY: build-images
build-images:
	make -C ./tests/e2e/chains/tendermint image

.PHONY: e2e-test
e2e-test: $(Signed_RustEnclave_Name) yrly
	LCP_BIN=$(LCP_BIN) ./tests/e2e/scripts/run_e2e_test.sh

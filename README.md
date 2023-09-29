# cosmos-ethereum-ibc-lcp

This repository contains multiple modules:

- An enclave contains ethereum and tendermint ELC
- A relayer between ethereum and tendermint
- MockApp(IBC-App) implementation in Go and Solidity

## Supported Versions

- [ibc-solidity v0.3.13](https://github.com/hyperledger-labs/yui-ibc-solidity/releases/tag/v0.3.13)
- [lcp v0.2.2](https://github.com/datachainlab/lcp/releases/tag/v0.2.2)
- [ethereum-elc v0.0.6](https://github.com/datachainlab/ethereum-elc/releases/tag/v0.0.6)
- [lcp-go v0.1.0](https://github.com/datachainlab/lcp-go/releases/tag/v0.1.0)
- [lcp-solidity v0.1.0](https://github.com/datachainlab/lcp-solidity/releases/tag/v0.1.0)
- [yui-relayer v0.4.2](https://github.com/hyperledger-labs/yui-relayer/releases/tag/v0.4.2)
- [ethereum-ibc-relay-chain v0.2.2](https://github.com/datachainlab/ethereum-ibc-relay-chain/releases/tag/v0.2.2)
- [ethereum-ibc-relay-prover v0.2.1](https://github.com/datachainlab/ethereum-ibc-relay-prover/releases/tag/v0.2.1)

## Build enclave and run E2E test

### SGX HW mode(default)

```
$ make all yrly prepare-contracts build-images
$ make e2e-test
```

### SGX SW mode

```
$ export SGX_MODE=SW
$ make all yrly prepare-contracts build-images
$ make e2e-test
```

------------

## How to build

### Build an enclave contains tendermint and ethereum ELC

```
# NOTE: the following command requires sgx-sdk to be installed in the environment
$ make
```

If succeeded, a signed enclave binary is created at `./bin/enclave.signed.so`.

### Relayer(between tendermint to ethereum)

```
$ make yrly
```

### Build a docker image of tendermint chain

```
$ make -C ./tests/e2e/chains/tendermint image
```

## Run E2E test (Manually)

### Prerequisite

- `lcp` command(from [lcp v0.2.2](https://github.com/datachainlab/lcp/releases/tag/v0.2.2)) is installed

### Launch local networks

The following command launches both tendermint and ethereum chains. It also deploys the solidity contract on the ethereum's execution chain.

```
$ make -C ./tests/e2e/cases/tm2eth network
```

### Remote Attestation

First, generate an Enclave Key

```
$ /path/to/lcp enclave generate-key --enclave=/path/to/enclave.signed.so
0x8b76f939e238a54c7a1ba46ed4c027dc21993cc3
# set ENCLAVE_KEY environment variable for the following steps
$ export ENCLAVE_KEY=0x8b76f939e238a54c7a1ba46ed4c027dc21993cc3
```

Next, execute the remote attestation with the IAS and get an AVR that contains the public key of the Enclave Key from the IAS

```
$ /path/to/lcp enclave ias-remote-attestation --enclave_key=${ENCLAVE_KEY} --enclave=/path/to/enclave.signed.so
```

### Modify Relayer config

You probably need to edit the `mrenclave`, `ibc_address` values in the some files under `./tests/e2e/cases/tm2eth/configs` with your own.

### Launch LCP service

```
$ /path/to/lcp service start --enclave=/path/to/enclave.signed.so --address=127.0.0.1:50051 --threads=2
```

### Run test

```
$ make -C ./tests/e2e/cases/tm2eth test
```

### Shutdown local networks

```
$ make -C ./tests/e2e/cases/tm2eth network-down
```

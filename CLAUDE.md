# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cross-chain messaging demo between Cosmos (Tendermint) and Ethereum using IBC + LCP (Light Client Proxy). LCP runs Tendermint and Ethereum light clients (ELCs) inside an Intel SGX enclave so that Ethereum-side proof verification is cheap, and is fronted by a Go relayer (`yrly`).

## Key Components

- **`enclave/`** — Rust `no_std` SGX enclave (built as static lib, signed into `bin/enclave.signed.so`). `enclave/src/lib.rs` registers light clients via `tendermint_lc` and `ethereum_elc` against the LCP `enclave-runtime`. The `PRESET` constant decides Ethereum spec (`preset::minimal` for the local devnet — must be switched to `preset::mainnet` for goerli/sepolia/holesky/mainnet builds).
- **`relayer/main.go`** — Builds `yrly`: a thin `cmd.Execute(...)` wiring of yui-relayer modules. Brings together tendermint chain, ethereum chain, ethereum LC prover (`ethereum-ibc-relay-prover`), LCP relay module (`lcp-go`), LCP-tendermint prover, HD signer, raw signer, and debug chain/prover. It contains no relay logic itself; behavior changes go upstream into those modules. Versions are pinned in `go.mod` and listed in README.md "Supported Versions".
- **`lcp/`** — Git submodule of the LCP service. The `lcp` binary used for `enclave generate-key`, `service start`, and remote attestation is built here (`make -C lcp`). E2E uses `lcp/bin/lcp`.
- **`tests/e2e/`** — End-to-end harness. `chains/ethereum` runs geth + lodestar (consensus) + deposit + lodestar-validator via `compose.yaml`, and deploys Solidity contracts (`contracts/contracts/App.sol`, `Dependencies.sol`) via Hardhat. `chains/tendermint` builds a Cosmos `simapp` Docker image. `cases/tm2eth` is the only test case and orchestrates `network → setup → handshake → test → test-operators → network-down`. Relayer config templates live in `cases/tm2eth/configs/templates/` and are rendered by `scripts/gen_rly_config.sh`.
- **`enclave/Cargo.toml`** pins `enclave-runtime`, `tendermint-lc`, and `ethereum-elc` to specific git revs. Bumps to LCP/ELC versions happen here and must stay in sync with the Go-side `lcp-go` / `ethereum-ibc-relay-prover` versions in `go.mod`. Rust toolchain is pinned by `rust-toolchain` (currently `nightly-2024-09-05`).

## Build

Requires Intel SGX SDK at `/opt/sgxsdk` (see README for install). Set `SGX_MODE=SW` to build/run on non-SGX hosts (insecure, for dev/CI only — CI runs in SW mode).

```bash
make                       # builds enclave/enclave.so → bin/enclave.signed.so
make yrly                  # builds bin/yrly (Go relayer, tags: customcert,ylry_debug)
make prepare-contracts     # npm install for Hardhat contracts
make build-images          # builds tendermint + ethereum (geth, lodestar, deposit, contracts) docker images
make fmt                   # cargo fmt across workspace and ./enclave
make clean                 # removes built enclave artifacts and runs cargo clean
```

The submodule `lcp/` must be checked out (`git submodule update --init --recursive`) before the E2E target builds `lcp/bin/lcp`.

## E2E Test

`make e2e-test` is the canonical test entry. It depends on `e2e-clean`, the `lcp` binary, the signed enclave, and `yrly`, then runs `tests/e2e/scripts/run_e2e_test.sh`.

Pass options through `E2E_OPTIONS`:

```bash
make e2e-test                                          # default
make E2E_OPTIONS="--mock_zkdcap --elc_updater" e2e-test  # what CI runs (SW mode)
make E2E_OPTIONS="--no_run_lcp" e2e-test               # connect to an already-running LCP service
make E2E_OPTIONS="--upgrade_test" e2e-test             # adds channel upgrade test
make E2E_OPTIONS="--enclave_debug" e2e-test
make E2E_OPTIONS="--key_expiration=3600" e2e-test
```

Supported flags: `--no_run_lcp`, `--zkdcap`, `--mock_zkdcap`, `--enclave_debug`, `--upgrade_test`, `--fakelost_test`, `--elc_updater`, `--key_expiration=<int>`. `LCP_RISC0_IMAGE_ID` must match the value baked into the LCP zkVM build when `--zkdcap` is used.

Sub-targets inside `tests/e2e/cases/tm2eth/Makefile` (`network`, `setup`, `handshake`, `test`, `test-channel-upgrade`, `test-operators`, `restore`, `network-down`) can be run directly when iterating without a full enclave rebuild — the README.md "Run E2E test (Manually)" section documents the manual flow including remote attestation and `mrenclave`/`ibc_address` config edits.

## Notes for Modifications

- Editing `relayer/main.go` is rarely the right fix; relay behavior almost always lives in the imported modules pinned in `go.mod`.
- After bumping `enclave/Cargo.toml` revs, also bump the matching Go modules in `go.mod` and the version table in README.md — they are expected to track together.
- Switching from devnet to a real Ethereum network requires changing `PRESET` in `enclave/src/lib.rs` from `preset::minimal` to `preset::mainnet`.
- `make e2e-test` first runs `e2e-clean` which removes `.openzeppelin` upgrade manifests via the `contracts` docker service; expect contract addresses to differ across runs.

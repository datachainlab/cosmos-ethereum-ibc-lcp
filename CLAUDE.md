# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cross-chain messaging demo between Cosmos (Tendermint) and Ethereum using IBC + LCP (Light Client Proxy). LCP runs Tendermint and Ethereum light clients (ELCs) inside an Intel SGX enclave so that Ethereum-side proof verification is cheap, and is fronted by a Go relayer (`yrly`). A second target chain — Polygon PoS — is wired in alongside Ethereum with scenario coverage matching tm2eth's core flows (handshake, packet relay, operators, channel upgrade) — see "Polygon (tm2pol)" below. tm2eth-specific options not yet ported to tm2pol: `--zkdcap` / `--mock_zkdcap`, `--elc_updater`, `--fakelost_test`, LCP-restart + `restore` mid-flow.

### Private polygon dependencies

`polygon-elc` (Rust, enclave) and `polygon-ibc-relay-prover` (Go, relayer) are pulled by **git rev** from `github.com/datachainlab/...`. Both repos are private; the public Go proxy / sumdb 404s on them, so `go build`/`go mod tidy` need:

```
export GOPRIVATE='github.com/datachainlab/polygon-ibc-relay-prover,github.com/datachainlab/polygon-elc'
```

(or the same value in `~/.netrc` / `go env -w`). For Rust, Cargo just clones the repo using local git credentials; no extra config needed. Setting `GOPRIVATE` is the developer's responsibility — `make yrly` does not set it.

## Key Components

- **`enclave/`** — Rust `no_std` SGX enclave (built as static lib, signed into `bin/enclave.signed.so`). `enclave/src/lib.rs` registers light clients via `tendermint_lc`, `ethereum_elc`, and `polygon_elc` against the LCP `enclave-runtime`. The `PRESET` constant decides Ethereum spec (`preset::minimal` for the local devnet — must be switched to `preset::mainnet` for goerli/sepolia/holesky/mainnet builds).
- **`relayer/main.go`** — Builds `yrly`: a thin `cmd.Execute(...)` wiring of yui-relayer modules. Brings together tendermint chain, ethereum chain, ethereum LC prover (`ethereum-ibc-relay-prover`), Polygon LC prover (`polygon-ibc-relay-prover`, registered as `polygonlc`), LCP relay module (`lcp-go`), LCP-tendermint prover, HD signer, raw signer, and debug chain/prover. It contains no relay logic itself; behavior changes go upstream into those modules. Versions are pinned in `go.mod` and listed in README.md "Supported Versions". `go.mod` carries `replace github.com/cometbft/cometbft => github.com/0xPolygon/cometbft v0.3.3-polygon` (the heimdall-v2 secp256k1-eth fork; superset of vanilla cometbft, so the existing tendermint chain still works); `polygon-ibc-relay-prover` is pulled by git rev (no replace) and requires `GOPRIVATE` to be set — see "Private polygon dependencies" above.
- **`lcp/`** — Git submodule of the LCP service. The `lcp` binary used for `enclave generate-key`, `service start`, and remote attestation is built here (`make -C lcp`). E2E uses `lcp/bin/lcp`. Pinned to `v0.2.17`; the enclave `Cargo.toml` revs must match.
- **`tests/e2e/`** — End-to-end harness, split into three subdirectories described in detail in [Test Harness Layout](#test-harness-layout) below.
- **`enclave/Cargo.toml`** pins `enclave-runtime` + `tendermint-lc` (lcp `v0.2.17`), `ethereum-elc` (`v0.1.0`), and `polygon-elc` (git rev — neither polygon repo has tags yet). Bumps to LCP/ELC versions happen here and must stay in sync with the Go-side `lcp-go` / `ethereum-ibc-relay-prover` / `polygon-ibc-relay-prover` versions in `go.mod`. The `[patch."https://github.com/datachainlab/lcp"]` block redirects `light-client`/`store`/`context`/`lcp-types`/`commitments`/`crypto`/`ocall-commands` to the local `lcp/` submodule — `ethereum-elc v0.1.0` was released against lcp `v0.2.14` and without the patch the graph ends up with two copies of every leaf crate, breaking the `dyn LightClientRegistry` cast. `getrandom` is pinned at `=0.2.8` so the existing `getrandom-sgx-lite` patch (only versioned for 0.2.8) actually applies — otherwise SGX linking fails on libc syscalls. Rust toolchain is pinned by `rust-toolchain` (currently `nightly-2025-08-25` — required by `base64ct 1.8.3`/edition2024 pulled in via lcp `v0.2.17`). Note: `polygon-elc` pulls a forked `tendermint-rs` (`polygon-heimdall-support` branch, secp256k1-eth feature) at version 0.40, which Cargo resolves alongside `tendermint-lc`'s 0.29 — both versions coexist in the dep tree.

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

## Test Harness Layout

`tests/e2e/` contains three sibling directories. Top-level orchestration in `scripts/` drives `chains/` (the local devnets) and `cases/` (the test scenarios) in that order.

### `tests/e2e/chains/` — local devnets

Each subdirectory builds the docker image(s) and `compose` services for one chain. They are independent: their `make network` / `network-down` targets bring the chain up or tear it down without knowing about the relayer.

- **`chains/tendermint/`** — Cosmos chain. The `simapp/` directory contains a custom SDK app (`app.go`, `ibc.go`, `genesis.go`, `ante.go`, `upgrades.go`, plus the `simd` and `tm-chain` binaries) with a `mockapp` IBC module used as the test app. `make image` builds `tendermint-chain:latest` from the `Dockerfile`. `docker-compose.yml` runs a single `tendermint-chain` container exposing 26656/26657/9090 with `IBC_CHANNEL_UPGRADE_TIMEOUT=480000000000` and the `LCP_RA_ROOT_CERT_HEX` / `LCP_DCAP_RA_ROOT_CERT_HEX` env vars used to inject the LCP attestation root cert in SW mode. `proto/` + `scripts/protocgen.sh` regenerate Go protobuf bindings via `make proto-gen`.
- **`chains/ethereum/`** — Ethereum execution + consensus stack. `compose.yaml` defines four runtime services (`geth`, `lodestar`, `deposit`, `lodestar-validator`) plus a build-only `contracts` service. `make build-images` (`build-geth-image` / `build-lodestar-image` / `build-deposit-image` / `build-contract-image`) builds the four images from `Dockerfile.geth`, `Dockerfile.lodestar`, `Dockerfile.deposit`, `Dockerfile.npm`. `make network` brings the stack up with `EPOCH_LATEST_HF=0` and a genesis timestamp 10s in the future; lodestar runs in `dev` mode with all forks (Altair → Electra) at epoch 0 and Fulu at `EPOCH_LATEST_HF`. Validator keys live under `consensus/validator_keys/` (regenerable via `setup-validator-key`) and the JWT secret used between geth and lodestar is in `config/jwtsecret`. `make deploy` runs `npx hardhat run ./scripts/deploy.js --network eth_local` inside the `contracts` service to deploy `contracts/contracts/App.sol` (the mockapp) and `Dependencies.sol`; `make extract-abi` then dumps ABIs and addresses. `make rm-oz-upgrades` clears the OpenZeppelin upgrade manifest under `.openzeppelin/` (called by the root `e2e-clean` target). `lib/forge-std` and `lib/risc0-ethereum` are git submodules pulled in for Foundry/zkDCAP support.
- **`chains/polygon/`** — thin wrapper around the [`kurtosis-pos`](https://github.com/0xPolygon/kurtosis-pos) Kurtosis package. `make network` runs `kurtosis run --enclave pos github.com/0xPolygon/kurtosis-pos`, which spins up an L1 (geth + lighthouse) plus the Polygon PoS L2 (one heimdall-v2 validator + one bor execution node). `make network-down` runs `kurtosis enclave rm --force pos`. Helpers `make {bor-rpc-url,heimdall-cometbft-url,heimdall-rest-url,heimdall-grpc-url}` shell out to `kurtosis port print` for the matching service. Default service names: `l2-el-1-bor-heimdall-v2-validator` (port id `rpc` = bor JSON-RPC) and `l2-cl-1-heimdall-v2-bor-validator` (port ids `rpc` / `http` / `grpc` = CometBFT 26657 / REST 1317 / gRPC 3132). Default L2 EL chain id is `4927`, CL chain id `heimdall-4927`. The polygon-side Solidity (IBCHandler + LCPClientIAS + AppV1, plus AppV2-V7 under `--upgrade_test`) lives in `chains/polygon/contracts/` and is deployed at `tm2pol` devnet bring-up.

### `tests/e2e/cases/` — test scenarios

`cases/tm2eth/` is the full Cosmos↔Ethereum scenario; `cases/tm2pol/` is the parallel Cosmos↔Polygon PoS scenario, covering the same core flows (handshake, packet relay, operators, optional channel upgrade).

- **`cases/tm2eth/Makefile`** — orchestration entry. Targets compose chain bring-up + relayer setup + scenarios:
  - `network` / `network-down` — bring both `chains/tendermint` and `chains/ethereum` up/down, then `deploy` and `extract-abi` on Ethereum.
  - `setup` — runs `scripts/fixture` (copies `key_seed.json` out of the tendermint container into `fixtures/`) and `scripts/init-rly` (initializes `~/.yui-relayer`, registers `configs/demo/`, and imports the tendermint signing key).
  - `handshake` — runs `scripts/handshake`: initializes the LCP-tendermint light client, adds the path from `configs/path.json`, creates clients on both sides, calls `lcp activate-client` for each, and finally completes the connection and channel handshakes.
  - `test` — runs `scripts/test-tx` (sends one packet from each side and waits for the relayer to drain unrelayed packets/acks) followed by `scripts/test-service` (runs `yrly service start` with relay/optimize intervals 20s/30s and validates ack drain).
  - `test-channel-upgrade` — runs `scripts/test-channel-upgrade`, a 9-case scenario covering channel upgrade init/cancel/timeout interleavings between the two chains.
  - `test-operators` — runs `scripts/test-operators` exercising `lcp update-operators` nonce semantics on both sides.
  - `restore` — runs `scripts/restore`: `lcp restore-elc` + `lcp remove-eki` on both sides, used after restarting the LCP service to recover ELC state.
  - `elc-updater-start` / `elc-updater-stop` — manage a sidecar `lcp elc-updater server` (sqlite-backed at `$ELC_UPDATER_DB`, default `/tmp/elc-updater.db`) on `localhost:50061` that pre-feeds ELC updates; toggled by `--elc_updater`.
- **`cases/tm2eth/configs/`** — `path.json` defines the IBC path (`ibc0` ↔ `ibc1`, port `mockapp`, version `mockapp-1`, unordered, naive strategy). `templates/ibc-{0,1}.json.tpl` and `ibc-{0,1}-zkdcap.json.tpl` are rendered into `configs/demo/ibc-{0,1}.json` by `scripts/gen_rly_config.sh` using `jq -n`, substituting `LCP_MRENCLAVE`, `LCP_KEY_EXPIRATION`, `IBC_ADDRESS` (read from `tests/e2e/chains/ethereum/contracts/addresses/IBCHandler`), `LC_ADDRESS` (`.../LCPClient`), and (for zkDCAP) `LCP_RISC0_IMAGE_ID` and `LCP_ZKDCAP_RISC0_MOCK`.
- The handshake/test scripts share env-var knobs — most notably `DEBUG_RELAYER_PRUNE_AFTER_BLOCKS_PROVER_ibc1` and `DEBUG_RELAYER_SHFU_WAIT_ibc0`, which are toggled by `USE_FAKELOST_TEST=yes` to simulate sync-committee finality update loss.

#### Polygon (tm2pol) — Phase 2d handshake + relay + operators + channel upgrade

`cases/tm2pol/` exercises the full LCP-mediated client + connection + channel handshake between Cosmos (`ibc0`, simapp) and Polygon PoS (`ibc1`, kurtosis-pos bor), bidirectional packet relay + ack drain, `lcp update-operators` nonce semantics on both sides, and (under `E2E_OPTIONS="--upgrade_test"`) the 9-case channel upgrade scenario. The Polygon-side Solidity (`IBCHandler`, `LCPClientIAS`, `AppV1`, and `AppV2`-`AppV7` only under upgrade test) is deployed at devnet bring-up. `foundry`'s `cast` must be on `$PATH` (used by `scripts/utils:sendPacketOnPol` to send the bor-side mockapp packet).

- **`cases/tm2pol/Makefile`** — `network` brings up `chains/tendermint` + `chains/polygon`, then `deploy extract-abi` on polygon; `network-down` tears both down; `setup` runs `fixture` (copy tendermint key seed) + `gen_rly_config.sh` + `init-rly`; `handshake` runs `scripts/handshake` (mirror of tm2eth's: `lcp-tendermint light init`, `tx clients`, `lcp activate-client` both sides, `tx connection`, `tx channel`); `test` runs `scripts/test-tx` (one packet each way, drain) then `scripts/test-service` (yrly service start with relay/optimize intervals 20s/30s, drain); `test-operators` runs `scripts/test-operators` (copied verbatim from tm2eth — the operator EOAs already match our `ibc-{0,1}.json.tpl`); `test-channel-upgrade` runs the 9-case upgrade scenario (copy of tm2eth's, with the fakelost/debug-wrapper branches stripped since tm2pol doesn't wrap chains with `/relayer.chains.debug.config.ChainConfig`); `test-timeout` runs `scripts/test-tx-timeout` (cosmos→polygon with `--packet-timeout-height 0-1`, polygon→cosmos with `timeoutTimestamp = now+1sec` — both expect `tx relay` to submit a `ProofUnreceived` timeout proof rather than delivering the packet).
- **`cases/tm2pol/scripts/utils`** — `expectUnrelayedCount` / `waitUnrelayedCount` helpers (same as tm2eth) plus `sendPacketOnPol`, which calls `cast send` against `AppV1.sendPacket(...)`. The sender is the kurtosis admin private key `0xd403…60ea` (only L2-prefunded EOA; the relayer's HD-signer EOA gets funded out of it during deploy but isn't used here). The rpc address jq path is `.chain.rpc_addr` directly because tm2pol's `ibc-1.json` doesn't use tm2eth's `debug` chain wrapper.
- **`cases/tm2pol/configs/`** — `path.json` (`ibc0`↔`ibc1` mockapp, version `mockapp-1`, unordered, naive); `templates/ibc-0.json.tpl` (cosmos chain + lcp-tendermint prover, `elc_client_id=07-tendermint-1`, EIP-712 operator domain points at polygon-side LCPClient with chain id 4927); `templates/ibc-1.json.tpl` (bor chain + lcp-wrapped polygon prover, `elc_client_id=polygon-0`, EIP-712 cosmos chain id `ibc0`). Both templates rendered via `jq -n` reading `IBC_ADDRESS` / `LC_ADDRESS` from `chains/polygon/contracts/addresses/` and kurtosis-derived endpoints.
- **`chains/polygon/contracts/`** — self-contained hardhat project (separate from `chains/ethereum/contracts/`). `package.json` pins yui-ibc-solidity v0.3.40, lcp-solidity v0.2.1, ethereum-ibc-relay-chain v0.3.21. `Dependencies.sol` is IAS-only — no risc0/DCAP imports — so no foundry submodule is needed. `hardhat.config.js` `bor_local` network reads `process.env.BOR_RPC_URL` (kurtosis port forwarding is dynamic) and lists **two** signers: the kurtosis admin private key `0xd403…60ea` (only L2-prefunded account) and a second key whose address matches the relayer's HD-signer EOA `0xa89F47…`. `scripts/deploy.js` uses signer[0] (admin) only to send 100 ETH to signer[1] (relayer EOA), then uses signer[1] for every contract deploy — that way `_deployer == owner() == relayer signer`, which `IBCContractUpgradableUUPSMockApp._isContractUpgrader` requires for `eth upgrade propose` to pass authorization. Deploys IBCHandler + LCPClientIAS + AppV1; under `USE_UPGRADE_TEST=yes` (set by `--upgrade_test`) also deploys AppV2-V7 and registers them via `proposeAppVersion(string,address,bytes)` — note that's the **3-arg** form per ethereum-ibc-relay-chain v0.3.21's current commit, not the 2-arg struct form some older commits accept. The contracts compose service uses `network_mode: host` to reach kurtosis's 127.0.0.1:NNNNN bor RPC port. The client type registered with the IBCHandler is `lcp-client-zkdcap` — lcp-go's relay module emits that string regardless of IAS/zkDCAP underneath; using any other registered name reverts with `IBCClientUnregisteredClientType`.
- **`tests/e2e/scripts/run_e2e_test_pol.sh`** — top-level driver invoked by `make e2e-test-pol`. At start, `pkill -f 'lcp.*service start'` reaps any stragglers from a previously-aborted run (a stale lcp left bound to :50051 would silently take precedence over the new instance and serve ELC state from the previous chain), and an `EXIT` trap kills the lcp it spawns so the next run starts clean. Then: brings up LCP, exports `LCP_RA_ROOT_CERT_HEX` / `LCP_DCAP_RA_ROOT_CERT_HEX` if `SGX_MODE=SW`, runs `make -C cases/tm2pol network` (which brings up tendermint + polygon + deploys contracts), waits for heimdall `/status`, runs `setup → handshake → [test-channel-upgrade] → test → test-operators → test-timeout`, then tears LCP and the devnets down. Parses `--upgrade_test` from `E2E_OPTIONS`, which sets `USE_UPGRADE_TEST=yes` (flowed through to the contracts compose service so `deploy.js` also deploys + proposes `AppV2`-`AppV7`) and overrides `IBC_CHANNEL_UPGRADE_TIMEOUT=60s` (vs tm2eth's 480s default — `chains/tendermint/docker-compose.yml` makes that env-overridable; the test-channel-upgrade sleeps were shortened to match). `make e2e-test-pol` depends on `e2e-clean-pol` which wipes polygon's `.openzeppelin/` upgrade manifest and tears down any leftover tendermint/polygon networks from a prior failed run. Recommendation: run `--upgrade_test` on a **fresh** devnet — kurtosis-pos's bor occasionally stalls (stops producing blocks while heimdall keeps going) after multi-hour runs, which surfaces as `LCPCommitmentTrustingPeriodHeaderFromFuture` during cases 8/9's timeout windows; this is an upstream stability quirk, not a tm2pol product bug.

### `tests/e2e/scripts/` — top-level orchestration & utilities

These scripts wire everything together; they are called from the root `Makefile` (`e2e-test`) or from CI.

- **`run_e2e_test.sh`** — the canonical entry called by `make e2e-test`. Parses `E2E_OPTIONS`, optionally invokes `init_lcp.sh` and starts the LCP service (`lcp service start --address=127.0.0.1:50051 --threads=2`), exports `LCP_MRENCLAVE` from `lcp enclave metadata`, brings up the local networks (`make -C cases/tm2eth network`), runs `gen_rly_config.sh`, waits for the first beacon `light_client/finality_update` (`http://localhost:19596/eth/v1/beacon/light_client/finality_update`), then runs `setup → handshake → [test-channel-upgrade] → restart-LCP+restore → test → [elc-updater-start + test + elc-updater-stop] → test-operators → network-down`. The LCP restart in the middle exists specifically to exercise the `restore` flow.
- **`init_lcp.sh`** — wipes `~/.lcp` and re-runs LCP attestation in the right mode for the env: `attestation ias` for SGX HW, `attestation simulate` (using `tests/certs/`) for SGX SW, or `attestation zkdcap` / `zkdcap-sim` (modes `dev` / `bonsai` / `local`) when `ZKDCAP=true`. Generates the enclave key inline via `lcp enclave generate-key --target_qe={qe,qe3,qe3sim}`.
- **`util`** — sourced helpers: `retry <max> <cmd...>` (used throughout) and `createDockerImageCacheKey` (escapes `/` in image names for cache file keys).
- **`wait-for-launch <max-attempts> <container>`** — polls `docker inspect` for `Health.Status == healthy`.
- **`save_docker_images <dir> <image...>`** / **`load_docker_images`** — `docker save` / `docker load` helpers, used to cache built images between CI steps.

## Notes for Modifications

- Editing `relayer/main.go` is rarely the right fix; relay behavior almost always lives in the imported modules pinned in `go.mod`.
- After bumping `enclave/Cargo.toml` revs, also bump the matching Go modules in `go.mod` and the version table in README.md — they are expected to track together. The `polygon-elc` (Rust) / `polygon-ibc-relay-prover` (Go) pair must move together.
- Switching from devnet to a real Ethereum network requires changing `PRESET` in `enclave/src/lib.rs` from `preset::minimal` to `preset::mainnet`.
- `make e2e-test` first runs `e2e-clean` which removes `.openzeppelin` upgrade manifests via the `contracts` docker service; expect contract addresses to differ across runs.
- `make e2e-test-pol` is the Polygon e2e driver (full handshake + relay + operators, plus channel upgrade under `E2E_OPTIONS="--upgrade_test"`). It depends on `e2e-clean-pol` which wipes polygon's `.openzeppelin/` upgrade manifest and tears down any leftover tendermint/polygon networks; expect contract addresses to differ across runs. Requires the `kurtosis` CLI in `$PATH`, Docker running, and foundry's `cast` for polygon-side packet sends. Not yet wired into CI (`.github/workflows/test.yml` only runs `e2e-test`).
- The `replace github.com/cometbft/cometbft => github.com/0xPolygon/cometbft v0.3.3-polygon` line in `go.mod` is load-bearing for the heimdall-v2 prover. Don't drop it. The fork is a superset of vanilla cometbft — the existing tendermint chain still verifies its ed25519 validator set under it.

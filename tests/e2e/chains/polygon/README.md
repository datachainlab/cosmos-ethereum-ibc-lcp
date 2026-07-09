# Polygon PoS devnet

Thin wrapper around the [`kurtosis-pos`](https://github.com/0xPolygon/kurtosis-pos) Kurtosis package.

## Prerequisites

- [`kurtosis`](https://docs.kurtosis.com/install) CLI
- Docker

## Make targets

- `make network` — `kurtosis run --enclave pos github.com/0xPolygon/kurtosis-pos@$(KURTOSIS_VERSION)`. We pin to a commit on `main` (currently `97722d0a6dd8ebf2ca0a18b760fda45cc067336b`, post `e3d4d1d` "align devnet config with amoy") so that the default 1-validator devnet runs bor in **archive mode** — the polygon prover calls `eth_getProof` at historical bor blocks tied to Heimdall milestones, and a non-archive validator only retains state for ~1024 blocks. The trade-off vs. the most recent tagged release `v1.3.1` (which doesn't have archive mode) is that the bor + heimdall services gain a `-archive` suffix in their names (`l2-el-1-bor-heimdall-v2-validator-archive` etc.), and we're tracking an untagged commit. Brings up the L1 (geth + lighthouse), Polygon PoS contract deployment, validator config generation, and an L2 with one heimdall-v2 validator + one bor execution node.
- `make network-down` — `kurtosis enclave rm --force pos`. Tears the enclave down.
- `make endpoints` — print bor JSON-RPC, heimdall CometBFT RPC, and heimdall Cosmos REST URLs as `KEY=URL` lines that can be `eval`'d.
- `make inspect` — `kurtosis enclave inspect pos`, prints the full service/port table.

`make build-images` / `make image` are no-ops; kurtosis pulls images on demand.

## Defaults

- Enclave name: `pos` (override with `KURTOSIS_ENCLAVE=...`).
- L2 EL chain id: `4927`. L2 CL chain id: `heimdall-4927`.
- Service names follow `l2-{cl,el}-<id>-<type>-<peer-type>-<kind>[-archive]` — for the default 1-validator setup at the pinned commit (`el_bor_archive_mode` defaults to true):
  - EL: `l2-el-1-bor-heimdall-v2-validator-archive` (port id `rpc` = bor JSON-RPC).
  - CL: `l2-cl-1-heimdall-v2-bor-validator-archive` (port ids `rpc` = CometBFT 26657, `http` = REST 1317, `grpc` = 3132).

Override `EL_SERVICE` / `CL_SERVICE` if you change the participant count or types.

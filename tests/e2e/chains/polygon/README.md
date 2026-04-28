# Polygon PoS devnet

Thin wrapper around the [`kurtosis-pos`](https://github.com/0xPolygon/kurtosis-pos) Kurtosis package.

## Prerequisites

- [`kurtosis`](https://docs.kurtosis.com/install) CLI
- Docker

## Make targets

- `make network` — `kurtosis run --enclave pos github.com/0xPolygon/kurtosis-pos`. Brings up the L1 (geth + lighthouse), Polygon PoS contract deployment, validator config generation, and an L2 with one heimdall-v2 validator + one bor execution node.
- `make network-down` — `kurtosis enclave rm --force pos`. Tears the enclave down.
- `make endpoints` — print bor JSON-RPC, heimdall CometBFT RPC, and heimdall Cosmos REST URLs as `KEY=URL` lines that can be `eval`'d.
- `make inspect` — `kurtosis enclave inspect pos`, prints the full service/port table.

`make build-images` / `make image` are no-ops; kurtosis pulls images on demand.

## Defaults

- Enclave name: `pos` (override with `KURTOSIS_ENCLAVE=...`).
- L2 EL chain id: `4927`. L2 CL chain id: `heimdall-4927`.
- Service names follow `l2-{cl,el}-<id>-<type>-<peer-type>-<kind>` — for the default 1-validator setup:
  - EL: `l2-el-1-bor-heimdall-v2-validator` (port id `rpc` = bor JSON-RPC).
  - CL: `l2-cl-1-heimdall-v2-bor-validator` (port ids `rpc` = CometBFT 26657, `http` = REST 1317, `grpc` = 3132).

Override `EL_SERVICE` / `CL_SERVICE` if you change the participant count or types.

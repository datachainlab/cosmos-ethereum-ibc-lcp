# Local Testnet for Ethereum

This environment consists of `geth` as Execution Client and `lodestar` as Consensus Client.

## Requirements

- [jq](https://stedolan.github.io/jq/)

## For Development

### Create jwt token for connection between execution node and beacon node

```
openssl rand -hex 32 | tr -d "\n" | sed -e 's/^/0x/' > "jwtsecret"
```

### Beacon API Example

[Beacon API](https://ethereum.github.io/beacon-APIs/?urls.primaryName=v2.3.0)

After running `lodestar` container, API request could be handled.

```
curl -s http://localhost:9596/eth/v1/beacon/genesis -X GET -H 'Content-Type: application/json'
```

## Metrics

### Prometheus

Access to [http://localhost:9090/](http://localhost:9090/)

### Ganache

Access to [http://localhost:3000/](http://localhost:3000/)

## Maintenance

Both Exectuion and Beacon node is under development. Development environment depends on those docker images.
So the below docker images must be watched on.

- [Geth](https://hub.docker.com/r/ethereum/client-go/tags)
- [Lodestar](https://hub.docker.com/r/chainsafe/lodestar/tags)

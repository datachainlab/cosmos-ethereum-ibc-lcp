FROM golang:1.23.6-bookworm AS build

COPY xion /xion
WORKDIR /xion
RUN make BUILD_TAGS=customcert install

FROM golang:1.23.6-bookworm

COPY --from=build /go/bin/xiond /bin
COPY --from=build /go/pkg/mod/github.com/!cosm!wasm/wasmvm/v2@v2.1.2/internal/api/libwasmvm.x86_64.so /lib
COPY scripts /root/scripts

WORKDIR /root

RUN apt-get update -y && apt-get install -y jq

ARG CHAINID
ARG CHAINDIR=/root/data
ARG RPCPORT=26657
ARG P2PPORT=26656
ARG PROFPORT=6060
ARG GRPCPORT=9090

RUN ./scripts/tm-chain xiond $CHAINID $CHAINDIR $RPCPORT $P2PPORT $PROFPORT $GRPCPORT

ENV CHAINID=$CHAINID
ENV CHAINDIR=$CHAINDIR
EXPOSE $RPCPORT $P2PPORT $PROFPORT $GRPCPORT
ENTRYPOINT ["./scripts/entrypoint.sh"]

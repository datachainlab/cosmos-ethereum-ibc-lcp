FROM golang:1.20.6-bookworm

COPY . /root/
WORKDIR /root

RUN go build -mod readonly -tags customcert -o /usr/bin/simd ./simapp/simd
RUN apt-get update -y && apt-get install -y jq

WORKDIR /root/simapp

ARG CHAINID
ARG CHAINDIR=/root/data
ARG RPCPORT=26657
ARG P2PPORT=26656
ARG PROFPORT=6060
ARG GRPCPORT=9090

RUN ./tm-chain simd $CHAINID $CHAINDIR $RPCPORT $P2PPORT $PROFPORT $GRPCPORT

ENV CHAINID=$CHAINID
ENV CHAINDIR=$CHAINDIR
EXPOSE $RPCPORT $P2PPORT $PROFPORT $GRPCPORT
ENTRYPOINT ["./entrypoint.sh"]

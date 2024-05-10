package types

import (
	ibcexported "github.com/cosmos/ibc-go/v8/modules/core/exported"
)

type Acknowledgement struct {
	data []byte
}

var _ ibcexported.Acknowledgement = (*Acknowledgement)(nil)

func NewAcknowledgement(data []byte) Acknowledgement {
	return Acknowledgement{data: data}
}

func (ack Acknowledgement) Success() bool {
	return true
}

func (ack Acknowledgement) Acknowledgement() []byte {
	return ack.data
}

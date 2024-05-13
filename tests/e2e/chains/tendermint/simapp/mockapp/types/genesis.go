package types

import (
	host "github.com/cosmos/ibc-go/v8/modules/core/24-host"
)

type GenesisState struct {
	PortId string `json:"port_id,omitempty"`
}

// NewGenesisState creates a new ibc-transfer GenesisState instance.
func NewGenesisState(portID string) *GenesisState {
	return &GenesisState{
		PortId: portID,
	}
}

// DefaultGenesisState returns a GenesisState with "transfer" as the default PortID.
func DefaultGenesisState() *GenesisState {
	return &GenesisState{
		PortId: PortID,
	}
}

// Validate performs basic genesis state validation returning an error upon any
// failure.
func (gs GenesisState) Validate() error {
	return host.PortIdentifierValidator(gs.PortId)
}

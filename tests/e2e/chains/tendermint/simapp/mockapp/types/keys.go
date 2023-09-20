package types

const (
	// ModuleName defines the IBC transfer name
	ModuleName = "mockapp"

	// Version defines the current version the IBC tranfer
	// module supports
	Version = "mockapp-1"

	// PortID is the default port id that transfer module binds to
	PortID = "mockapp"

	// StoreKey is the store key string for IBC transfer
	StoreKey = ModuleName

	// RouterKey is the message route for IBC transfer
	RouterKey = ModuleName

	// QuerierRoute is the querier route for IBC transfer
	QuerierRoute = ModuleName
)

var (
	// PortKey defines the key to store the port ID in store
	PortKey = []byte{0x01}
)

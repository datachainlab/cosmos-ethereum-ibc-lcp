package main

import (
	"os"

	"github.com/cosmos/cosmos-sdk/server"
	svrcmd "github.com/cosmos/cosmos-sdk/server/cmd"

	"github.com/datachainlab/cosmos-ethereum-ibc-lcp/tests/e2e/chains/tendermint/simapp"
	"github.com/datachainlab/cosmos-ethereum-ibc-lcp/tests/e2e/chains/tendermint/simapp/simd/cmd"
	"github.com/datachainlab/lcp-go/sgx/ias"
)

func main() {
	rootCmd, _ := cmd.NewRootCmd()

	// WARNING: if you use the simd in production, you must remove the following code:
	ias.SetAllowDebugEnclaves()
	defer ias.UnsetAllowDebugEnclaves()
	// END WARNING

	if err := svrcmd.Execute(rootCmd, "simd", simapp.DefaultNodeHome); err != nil {
		switch e := err.(type) {
		case server.ErrorCode:
			os.Exit(e.Code)

		default:
			os.Exit(1)
		}
	}
}

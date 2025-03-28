package main

import (
	"os"

	"cosmossdk.io/log"

	svrcmd "github.com/cosmos/cosmos-sdk/server/cmd"

	"github.com/datachainlab/cosmos-ethereum-ibc-lcp/tests/e2e/chains/tendermint/simapp"
	"github.com/datachainlab/cosmos-ethereum-ibc-lcp/tests/e2e/chains/tendermint/simapp/simd/cmd"
	"github.com/datachainlab/lcp-go/sgx"
)

func main() {
	// WARNING: if you use the simd in production, you must remove the following code:
	isAllowDebugEnclaves := os.Getenv("LCP_ENCLAVE_DEBUG")
	if isAllowDebugEnclaves == "1" {
		sgx.SetAllowDebugEnclaves()
		defer sgx.UnsetAllowDebugEnclaves()
	}
	rootCmd := cmd.NewRootCmd()
	if err := svrcmd.Execute(rootCmd, "", simapp.DefaultNodeHome); err != nil {
		log.NewLogger(rootCmd.OutOrStderr()).Error("failure when running app", "err", err)
		os.Exit(1)
	}
}

package main

import (
	"fmt"
	"os"
)

// version is set at build time via -ldflags.
var version = "dev"

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "concordd:", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	cmd := "help"
	if len(args) > 0 {
		cmd = args[0]
	}

	switch cmd {
	case "version":
		fmt.Println("concordd", version)
	case "help", "-h", "--help":
		usage()
	default:
		usage()
		return fmt.Errorf("unknown command %q", cmd)
	}
	return nil
}

func usage() {
	fmt.Println(`concordd - Concord distributed ledger node

Usage:
  concordd <command>

Commands:
  version    Print the node version
  help       Show this help

More commands (start, init) arrive with later build phases.`)
}

package main

import "testing"

func TestRunVersion(t *testing.T) {
	if err := run([]string{"version"}); err != nil {
		t.Fatalf("version command failed: %v", err)
	}
}

func TestRunHelp(t *testing.T) {
	if err := run([]string{"help"}); err != nil {
		t.Fatalf("help command failed: %v", err)
	}
}

func TestRunUnknown(t *testing.T) {
	if err := run([]string{"bogus"}); err == nil {
		t.Fatal("expected error for unknown command, got nil")
	}
}

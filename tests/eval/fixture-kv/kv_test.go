package main

import "testing"

func TestParse(t *testing.T) {
	m := Parse("a=1\nb = 2\n")
	if m["a"] != "1" || m["b"] != "2" {
		t.Fatalf("got %v", m)
	}
}

func TestParseIgnoresComments(t *testing.T) {
	m := Parse("# settings\na=1\n")
	if len(m) != 1 {
		t.Fatalf("comment line was parsed: %v", m)
	}
}

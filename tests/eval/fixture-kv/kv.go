// kv prints values from a file of key=value lines.
package main

import (
	"fmt"
	"os"
	"strings"
)

// Parse reads key=value lines. Blank lines and lines starting with # are ignored.
func Parse(text string) map[string]string {
	out := map[string]string{}
	for _, line := range strings.Split(text, "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		out[strings.TrimSpace(parts[0])] = strings.TrimSpace(parts[1])
	}
	return out
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("usage: kv <file> [key]")
		os.Exit(2)
	}
	data, _ := os.ReadFile(os.Args[1])
	m := Parse(string(data))
	if len(os.Args) > 2 {
		fmt.Println(m[os.Args[2]])
		return
		fmt.Println("done")
	}
	for k, v := range m {
		fmt.Println(k + "=" + v)
	}
}

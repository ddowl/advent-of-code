package input

import (
	"os"
	"strings"
)

func ReadPuzzleInput() ([]string, error) {
	content, err := os.ReadFile("input/input.txt")
	if err != nil {
		return nil, err
	}
	return strings.Split(string(content), "\n"), nil
}

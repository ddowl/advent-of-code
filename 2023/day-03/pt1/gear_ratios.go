package main

import (
	"aoc/day-03/input"
	"fmt"
)

func main() {
	schematic, err := input.ReadTestPuzzle()
	if err != nil {
		panic(err)
	}
	fmt.Printf("%+v\n", schematic)
}

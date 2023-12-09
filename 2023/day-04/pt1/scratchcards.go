package main

import (
	"aoc/day-04/input"
	"fmt"
)

func main() {
	scratchcards, err := input.ParseTestPuzzle()
	if err != nil {
		panic(err)
	}
	fmt.Printf("%+v\n", scratchcards)
}

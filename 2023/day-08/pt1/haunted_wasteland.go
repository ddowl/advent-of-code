package main

import (
	"aoc/day-08/input"
	"fmt"
)

func main() {
	network := input.Parse("input/test.txt")
	fmt.Printf("%+v\n", network)
}

package main

import (
	"aoc/day-06/input"
	"fmt"
)

func main() {
	races, err := input.ParseTest()
	if err != nil {
		panic(err)
	}
	fmt.Printf("%+v\n", races)
}

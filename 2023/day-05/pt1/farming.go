package main

import (
	"aoc/day-05/input"
	"fmt"
)

func main() {
	almanac, err := input.ParseTest()
	if err != nil {
		panic(err)
	}
	fmt.Printf("%+v\n", almanac)
}

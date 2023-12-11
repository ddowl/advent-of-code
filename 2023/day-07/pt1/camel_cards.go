package main

import (
	"aoc/day-07/input"
	"fmt"
)

func main() {
	hands, err := input.ParseTest()
	if err != nil {
		panic(err)
	}
	fmt.Printf("%+v\n", hands)
}

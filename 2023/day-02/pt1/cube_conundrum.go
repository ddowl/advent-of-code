package main

import (
	"aoc/day-02/input"
	"fmt"
)

func main() {
	games, err := input.ReadPuzzleTest()
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Printf("%+v\n", games)
}

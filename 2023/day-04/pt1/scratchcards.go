package main

import (
	"aoc/day-04/input"
	"fmt"

	"github.com/samber/lo"
)

func main() {
	scratchcards, err := input.ParsePuzzle()
	if err != nil {
		panic(err)
	}
	// fmt.Printf("%+v\n", scratchcards)

	numWins := lo.Map(scratchcards, func(scratchcard input.ScratchCard, _ int) int {
		// For each scratch card, count how many of our numbers are in the set of winning numbers
		return len(lo.Filter(scratchcard.Numbers, func(n, index int) bool {
			return lo.Contains(scratchcard.WinningNumbers, n)
		}))
	})
	// fmt.Println(numWins)

	points := lo.Map(numWins, func(wins int, _ int) int {
		if wins == 0 {
			return 0
		} else {
			return 1 << (wins - 1)
		}
	})
	// fmt.Println(points)
	fmt.Println(lo.Sum(points))
}

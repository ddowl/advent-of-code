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

	numScratchcards := make([]int, len(scratchcards))
	for i := 0; i < len(scratchcards); i++ {
		numScratchcards[i] = 1
	}

	// fmt.Println(numScratchcards)

	for i := 0; i < len(scratchcards); i++ {
		wins := numWins[i]
		copiesEarned := numScratchcards[i]

		for j := 0; j < wins; j++ {
			numScratchcards[i+j+1] += copiesEarned
		}
	}
	// fmt.Println(numScratchcards)
	fmt.Println(lo.Sum(numScratchcards))
}

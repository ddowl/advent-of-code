package main

import (
	"aoc/day-06/input"
	"errors"
	"fmt"

	"github.com/samber/lo"
)

func numWaysToWin(race input.Race) (int, error) {
	start := -1
	fmt.Println("processing race: ", race)
	for t := 0; t <= race.Time; t++ {
		v := t
		distance := v * (race.Time - t)
		// fmt.Println("distance: ", distance)
		if distance > race.Distance && start == -1 {
			start = t
		}
		if distance <= race.Distance && start != -1 {
			println("found a way to win: ", start, t)
			return t - start, nil
		}
	}
	return -1, errors.New("no way to win")
}

func main() {
	races, err := input.Parse()
	if err != nil {
		panic(err)
	}
	fmt.Printf("%+v\n", races)
	winCounts := lo.Map(races, func(race input.Race, _ int) int {
		waysToWin, err := numWaysToWin(race)
		if err != nil {
			panic(err)
		}
		return waysToWin
	})
	fmt.Println("ways to win each race: ", winCounts)
	product := lo.Reduce(winCounts, func(acc int, wins int, _ int) int { return acc * wins }, 1)
	fmt.Println("total product: ", product)
}

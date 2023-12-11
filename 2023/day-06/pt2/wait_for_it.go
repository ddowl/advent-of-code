package main

import (
	"aoc/day-06/input"
	"errors"
	"fmt"
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
	race, err := input.ParseTest2()
	if err != nil {
		panic(err)
	}
	fmt.Printf("%+v\n", race)
}

package main

import (
	"aoc/day-02/input"
	"fmt"
)

func fewestCubesInBag(game input.Game) map[string]int {
	bagContents := map[string]int{
		"red":   0,
		"green": 0,
		"blue":  0,
	}

	for _, cubes := range game.Reveals {
		for _, cube := range cubes {
			bagContents[cube.Color] = max(cube.Num, bagContents[cube.Color])
		}
	}

	return bagContents
}

func main() {
	games, err := input.ReadPuzzle()
	if err != nil {
		fmt.Println(err)
		return
	}

	// Compute fewest cubes in bag for each game
	minBags := make([]map[string]int, 0)
	for _, game := range games {
		minBags = append(minBags, fewestCubesInBag(game))
	}

	// Sum the powers each set of cubes
	sumOfPowers := 0
	for _, bag := range minBags {
		sumOfPowers += bag["red"] * bag["green"] * bag["blue"]
	}

	print(sumOfPowers)
}

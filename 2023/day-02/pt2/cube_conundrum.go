package main

import (
	"aoc/day-02/input"
	"fmt"

	"github.com/samber/lo"
	lop "github.com/samber/lo/parallel"
)

func fewestCubesInBag(game input.Game, idx int) map[string]int {
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
	minBags := lop.Map(games, fewestCubesInBag)

	// Sum the powers each set of cubes
	sumOfPowers := lo.Reduce(minBags, func(acc int, bag map[string]int, idx int) int {
		acc += bag["red"] * bag["green"] * bag["blue"]
		return acc
	}, 0)

	print(sumOfPowers)
}

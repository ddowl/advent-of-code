package main

import (
	"aoc/day-02/input"
	"fmt"
)

func possible(game input.Game, bagContents map[string]int) bool {
	for _, cubes := range game.Reveals {
		for _, cube := range cubes {
			if bagContents[cube.Color] < cube.Num {
				return false
			}
		}
	}
	return true
}

func main() {
	games, err := input.ReadPuzzle()
	if err != nil {
		fmt.Println(err)
		return
	}

	bagContents := map[string]int{
		"red":   12,
		"green": 13,
		"blue":  14,
	}

	possibleGames := make([]input.Game, 0)
	for _, game := range games {
		if possible(game, bagContents) {
			possibleGames = append(possibleGames, game)
		}
	}

	idSum := 0
	for _, game := range possibleGames {
		idSum += game.ID
	}
	fmt.Println(idSum)
}

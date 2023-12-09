package main

import (
	"aoc/day-03/input"
	"fmt"

	"github.com/samber/lo"
)

type Gear struct {
	X                   int
	Y                   int
	AdjacentPartNumbers []int
}

func (g Gear) Ratio() int {
	return lo.Reduce(g.AdjacentPartNumbers, func(acc int, partNum int, _ int) int {
		return acc * partNum
	}, 1)
}

type Rectangle struct {
	X1 int
	X2 int
	Y1 int
	Y2 int
}

func isAdjacent(symPos input.SymbolPosition, bounds Rectangle) bool {
	return symPos.Y >= bounds.Y1 && symPos.Y <= bounds.Y2 && symPos.X >= bounds.X1 && symPos.X <= bounds.X2
}

func getAdjacencyBounds(numPos input.NumberPosition) Rectangle {
	return Rectangle{
		Y1: numPos.Y - 1,
		Y2: numPos.Y + 1,
		X1: numPos.XStart - 1,
		X2: numPos.XEnd + 1,
	}
}

func main() {
	schematic, err := input.ParsePuzzle()
	if err != nil {
		panic(err)
	}
	// fmt.Printf("%+v\n", schematic)
	numbers := schematic.NumberPositions
	symbols := schematic.SymbolPositions

	gears := lo.FilterMap(symbols, func(symPos input.SymbolPosition, _ int) (Gear, bool) {
		// Find adjacent part numbers to this gear symbol
		if symPos.Symbol != "*" {
			return Gear{}, false
		}
		adjacentNums := lo.FilterMap(numbers, func(numPos input.NumberPosition, _ int) (int, bool) {
			adjBounds := getAdjacencyBounds(numPos)
			if isAdjacent(symPos, adjBounds) {
				return numPos.Number, true
			} else {
				return -1, false
			}
		})
		if len(adjacentNums) != 2 {
			return Gear{}, false
		}
		return Gear{X: symPos.X, Y: symPos.Y, AdjacentPartNumbers: adjacentNums}, true
	})
	// fmt.Printf("%+v\n", gears)

	sumOfGearRatios := lo.Sum(lo.Map(gears, func(gear Gear, _ int) int {
		return gear.Ratio()
	}))
	fmt.Println(sumOfGearRatios)
}

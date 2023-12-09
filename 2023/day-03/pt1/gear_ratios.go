package main

import (
	"aoc/day-03/input"
	"fmt"

	"github.com/samber/lo"
)

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

func isPartNumber(numPos input.NumberPosition, symbolPositions []input.SymbolPosition) bool {
	adjBounds := getAdjacencyBounds(numPos)
	return lo.SomeBy(symbolPositions, func(symPos input.SymbolPosition) bool {
		return isAdjacent(symPos, adjBounds)
	})
}

func main() {
	schematic, err := input.ParsePuzzle()
	if err != nil {
		panic(err)
	}
	numbers := schematic.NumberPositions
	symbols := schematic.SymbolPositions

	partNumbers := lo.Filter(numbers, func(pos input.NumberPosition, _ int) bool {
		return isPartNumber(pos, symbols)
	})

	partNumberSum := lo.Sum(lo.Map(partNumbers, func(pos input.NumberPosition, _ int) int {
		return pos.Number
	}))

	fmt.Println(partNumberSum)
}

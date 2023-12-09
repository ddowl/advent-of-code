package main

import (
	"aoc/day-03/input"
	"fmt"

	"github.com/samber/lo"
)

func isPartNumber(numPos input.NumberPosition, symbolPositions []input.Position) bool {
	y1 := numPos.Y - 1
	y2 := numPos.Y + 1
	x1 := numPos.XStart - 1
	x2 := numPos.XEnd + 1
	return lo.SomeBy(symbolPositions, func(symPos input.Position) bool {
		// Is the given symbol adjacent to the number?
		return symPos.Y >= y1 && symPos.Y <= y2 && symPos.X >= x1 && symPos.X <= x2
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

package input

import (
	"os"
	"regexp"
	"strconv"
	"strings"

	"github.com/samber/lo"
)

type EngineSchematic struct {
	NumberPositions []NumberPosition
	SymbolPositions []SymbolPosition
}

type NumberPosition struct {
	Number int
	Y      int
	XStart int
	XEnd   int
}

type SymbolPosition struct {
	Symbol string
	X      int
	Y      int
}

var DigitRegex = regexp.MustCompile(`\d+`)
var SymbolRegex = regexp.MustCompile(`[^\w\s.]`)

func parsePuzzle(filename string) (*EngineSchematic, error) {
	contents, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	lines := strings.Split(string(contents), "\n")

	// To parse, map over lines twice, running a multichar digit regex and a symbol regex to collect
	// number and symbol positions.
	numberPositions := lo.FlatMap(lines, func(line string, row int) []NumberPosition {
		return lo.Map(DigitRegex.FindAllStringIndex(line, -1), func(idxs []int, index int) NumberPosition {
			num, err := strconv.Atoi(line[idxs[0]:idxs[1]])
			if err != nil {
				panic(err)
			}
			return NumberPosition{Number: num, Y: row, XStart: idxs[0], XEnd: idxs[1] - 1}
		})
	})

	symbolPositions := lo.FlatMap(lines, func(line string, row int) []SymbolPosition {
		return lo.Map(SymbolRegex.FindAllStringIndex(line, -1), func(idxs []int, index int) SymbolPosition {
			return SymbolPosition{Symbol: string(line[idxs[0]]), X: idxs[0], Y: row}
		})
	})

	return &EngineSchematic{NumberPositions: numberPositions, SymbolPositions: symbolPositions}, nil
}

func ParsePuzzle() (*EngineSchematic, error) {
	return parsePuzzle("input/input.txt")
}

func ParseTestPuzzle() (*EngineSchematic, error) {
	return parsePuzzle("input/test.txt")
}

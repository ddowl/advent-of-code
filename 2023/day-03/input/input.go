package input

import (
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"

	"github.com/samber/lo"
)

type EngineSchematic struct {
	NumberPositions []NumberPosition
	SymbolPositions []Position
}

type NumberPosition struct {
	Number int
	Y      int
	XStart int
	XEnd   int
}

type Position struct {
	X int
	Y int
}

var DigitRegex = regexp.MustCompile(`\d+`)
var SymbolRegex = regexp.MustCompile(`[^\w\s.]`)

func readPuzzle(filename string) (*EngineSchematic, error) {
	contents, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	lines := strings.Split(string(contents), "\n")
	fmt.Println(lines)

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

	symbolPositions := lo.FlatMap(lines, func(line string, row int) []Position {
		return lo.Map(SymbolRegex.FindAllStringIndex(line, -1), func(idxs []int, index int) Position {
			return Position{X: idxs[0], Y: row}
		})
	})

	return &EngineSchematic{NumberPositions: numberPositions, SymbolPositions: symbolPositions}, nil
}

func ReadPuzzle() (*EngineSchematic, error) {
	return readPuzzle("input/input.txt")
}

func ReadTestPuzzle() (*EngineSchematic, error) {
	return readPuzzle("input/test.txt")
}

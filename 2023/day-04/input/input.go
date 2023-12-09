package input

import (
	"os"
	"strconv"
	"strings"

	"github.com/samber/lo"
)

type ScratchCard struct {
	ID             int
	WinningNumbers []int
	Numbers        []int
}

func parsePuzzle(filename string) ([]ScratchCard, error) {
	contents, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	lines := strings.Split(string(contents), "\n")

	splitInTwo := func(s string, delim string) (string, string) {
		substrs := strings.Split(s, delim)
		return substrs[0], substrs[1]
	}

	expectNumber := func(s string) int {
		n, err := strconv.Atoi(s)
		if err != nil {
			panic(err)
		}
		return n
	}

	parseNumbers := func(s string) []int {
		return lo.Map(strings.Fields(s), func(nStr string, _ int) int {
			return expectNumber(nStr)
		})
	}

	scratchcards := lo.Map(lines, func(line string, _ int) ScratchCard {
		cardIdStr, numberDataStr := splitInTwo(line, ":")

		id := expectNumber(strings.Fields(cardIdStr)[1])
		winningNumbersStr, numbersStr := splitInTwo(numberDataStr, " | ")

		return ScratchCard{
			ID:             id,
			WinningNumbers: parseNumbers(winningNumbersStr),
			Numbers:        parseNumbers(numbersStr),
		}
	})
	return scratchcards, nil
}

func ParsePuzzle() ([]ScratchCard, error) {
	return parsePuzzle("input/input.txt")
}

func ParseTestPuzzle() ([]ScratchCard, error) {
	return parsePuzzle("input/test.txt")
}

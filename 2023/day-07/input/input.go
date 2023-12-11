package input

import (
	"os"
	"strconv"
	"strings"

	"github.com/samber/lo"
)

func splitInTwo(s string, delim string) (string, string) {
	ss := strings.Split(s, delim)
	return ss[0], ss[1]
}

func expectNumber(s string) int {
	n, err := strconv.Atoi(s)
	if err != nil {
		panic(err)
	}
	return n
}

func parseNumbers(s string) []int {
	return lo.Map(strings.Fields(s), func(nStr string, _ int) int {
		return expectNumber(nStr)
	})
}

type Hand struct {
	Cards string
	Bid   int
}

func parse(filename string) ([]Hand, error) {
	contents, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	lines := strings.Split(string(contents), "\n")
	return lo.Map(lines, func(line string, _ int) Hand {
		cardsStr, bidStr := splitInTwo(line, " ")

		return Hand{
			Cards: cardsStr,
			Bid:   expectNumber(bidStr),
		}
	}), nil
}

func Parse() ([]Hand, error) {
	return parse("input/input.txt")
}

func ParseTest() ([]Hand, error) {
	return parse("input/test.txt")
}

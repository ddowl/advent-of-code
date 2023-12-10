package input

import (
	"os"
	"strconv"
	"strings"

	"github.com/samber/lo"
)

type Almanac struct {
	Seeds []int
	Maps  [][]Range
}

type Range struct {
	DestStart   int
	SourceStart int
	Len         int
}

func parse(filename string) (Almanac, error) {
	contents, err := os.ReadFile(filename)
	if err != nil {
		return Almanac{}, err
	}
	groups := strings.Split(string(contents), "\n\n")

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

	seeds := parseNumbers(strings.Split(groups[0], ": ")[1])

	mapStrs := groups[1:]
	maps := lo.Map(mapStrs, func(mapStr string, _ int) []Range {
		rangeLines := strings.Split(mapStr, "\n")[1:]
		return lo.Map(rangeLines, func(rangeLine string, _ int) Range {
			ns := parseNumbers(rangeLine)
			return Range{
				DestStart:   ns[0],
				SourceStart: ns[1],
				Len:         ns[2],
			}
		})
	})
	return Almanac{Seeds: seeds, Maps: maps}, nil
}

func Parse() (Almanac, error) {
	return parse("input/input.txt")
}

func ParseTest() (Almanac, error) {
	return parse("input/test.txt")
}

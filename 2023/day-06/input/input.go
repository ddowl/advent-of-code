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

type Race struct {
	Time     int
	Distance int
}

func parse(filename string) ([]Race, error) {
	content, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	timeStr, distanceStr := splitInTwo(string(content), "\n")
	times := parseNumbers(strings.Split(timeStr, ":")[1])
	distances := parseNumbers(strings.Split(distanceStr, ":")[1])

	return lo.Map(lo.Zip2(times, distances), func(pair lo.Tuple2[int, int], _ int) Race {
		return Race{pair.A, pair.B}
	}), nil
}

func parse2(filename string) (Race, error) {
	content, err := os.ReadFile(filename)
	if err != nil {
		return Race{}, err
	}
	splitInTwo := func(s string, delim string) (string, string) {
		ss := strings.Split(s, delim)
		return ss[0], ss[1]
	}
	timeStr, distanceStr := splitInTwo(string(content), "\n")
	time := expectNumber(strings.ReplaceAll(strings.Split(timeStr, ":")[1], " ", ""))
	distance := expectNumber(strings.ReplaceAll(strings.Split(distanceStr, ":")[1], " ", ""))
	return Race{time, distance}, nil
}

func Parse() ([]Race, error) {
	return parse("input/input.txt")
}

func ParseTest() ([]Race, error) {
	return parse("input/test.txt")
}

func Parse2() (Race, error) {
	return parse2("input/input.txt")
}

func ParseTest2() (Race, error) {
	return parse2("input/test.txt")
}

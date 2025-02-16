package input

import (
	"os"
	"strconv"
	"strings"

	"github.com/samber/lo"
)

func Parse(filename string) ([]int, []int) {
	content, err := os.ReadFile("input/input.txt")
	if err != nil {
		panic(err)
	}

	intTuples := lo.Map(strings.Split(string(content), "\n"), func(s string, _ int) lo.Tuple2[int, int] {
		ss := strings.Split(s, "   ")
		a, err := strconv.Atoi(ss[0])
		if err != nil {
			panic(err)
		}
		b, err := strconv.Atoi(ss[1])
		if err != nil {
			panic(err)
		}
		return lo.Tuple2[int, int]{A: a, B: b}
	})

	return lo.Unzip2(intTuples)
}

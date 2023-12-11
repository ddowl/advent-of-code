package main

import (
	"aoc/day-05/input"
	"fmt"
	"math"

	"github.com/samber/lo"
	lop "github.com/samber/lo/parallel"
)

/*
This solution could be better optimized.
E.g. we could use the fact that many inputs map to the same outputs to compress our
category maps into one seed-to-location map, and compress seed inputs into ranges that apply to the domain of that map.
*/

type CategoryMap struct {
	Ranges []input.Range
}

func (cm CategoryMap) ToDestCategory(n int) int {
	for _, rg := range cm.Ranges {
		if n >= rg.SourceStart && n <= (rg.SourceStart+rg.Len) {
			// `n` falls into this range!
			return rg.DestStart + n - rg.SourceStart
		}
	}
	return n
}

func toLocNum(seed int, categoryMaps []CategoryMap) int {
	catNum := seed
	for _, cm := range categoryMaps {
		catNum = cm.ToDestCategory(catNum)
	}
	return catNum
}

func main() {
	almanac, err := input.Parse()
	if err != nil {
		panic(err)
	}

	categoryMaps := lo.Map(almanac.Maps, func(rgs []input.Range, _ int) CategoryMap {
		return CategoryMap{Ranges: rgs}
	})
	fmt.Println(almanac.Seeds)
	// fmt.Println(categoryMaps)

	locationNums := lop.Map(lo.Chunk(almanac.Seeds, 2), func(pair []int, _ int) int {
		fmt.Println("starting pair: ", pair)
		locNumChan := make(chan int, pair[1])

		for i := pair[0]; i < pair[0]+pair[1]; i++ {
			go func(n int) {
				locNum := toLocNum(n, categoryMaps)
				locNumChan <- locNum
			}(i)
		}

		minLocationNum := math.MaxInt64
		for i := 0; i < pair[1]; i++ {
			locNum := <-locNumChan
			minLocationNum = min(minLocationNum, locNum)
		}
		fmt.Println("min location num: ", minLocationNum)
		return minLocationNum
	})

	fmt.Println(locationNums)
	fmt.Println(lo.Min(locationNums))
}

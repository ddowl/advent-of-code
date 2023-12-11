package main

import (
	"aoc/day-05/input"
	"fmt"

	"github.com/samber/lo"
)

type CategoryMap struct {
	Ranges []input.Range
}

func (cm CategoryMap) ToSourceCategory(n int) int {
	for _, rg := range cm.Ranges {
		if n >= rg.DestStart && n < (rg.DestStart+rg.Len) {
			// `n` falls into this range!
			return rg.SourceStart + n - rg.DestStart
		}
	}
	return n
}

func toSeedNum(loc int, categoryMaps []CategoryMap) int {
	catNum := loc
	for i := len(categoryMaps) - 1; i >= 0; i-- {
		cm := categoryMaps[i]
		catNum = cm.ToSourceCategory(catNum)
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
	// fmt.Println(almanac.Seeds)
	seedRanges := lo.Chunk(almanac.Seeds, 2)

	// Check all location numbers starting from 0
	// break after finding first instance that maps to a seed number
	for locNum := 0; true; locNum++ {
		seedNum := toSeedNum(locNum, categoryMaps)

		if lo.ContainsBy(seedRanges, func(pair []int) bool {
			return seedNum >= pair[0] && seedNum < pair[0]+pair[1]
		}) {
			fmt.Println("Found lowest seed number", seedNum, "at location", locNum)
			break
		}
	}
}

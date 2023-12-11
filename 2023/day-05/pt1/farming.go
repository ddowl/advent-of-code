package main

import (
	"aoc/day-05/input"
	"fmt"

	"github.com/samber/lo"
)

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

func main() {
	almanac, err := input.Parse()
	if err != nil {
		panic(err)
	}
	// fmt.Printf("%+v\n", almanac)

	categoryMaps := lo.Map(almanac.Maps, func(rgs []input.Range, _ int) CategoryMap {
		return CategoryMap{Ranges: rgs}
	})

	locationNums := lo.Map(almanac.Seeds, func(seed int, _ int) int {
		catNum := seed
		for _, cm := range categoryMaps {
			catNum = cm.ToDestCategory(catNum)
		}
		return catNum
	})
	fmt.Println(lo.Min(locationNums))
}

package main

import (
	"day-01/input"
	"math"
	"sort"
)

func calculateTotalDistance(left, right []int) int {
	// Sort copies of input slices
	leftSorted := append([]int{}, left...)
	rightSorted := append([]int{}, right...)
	sort.Ints(leftSorted)
	sort.Ints(rightSorted)

	totalDistance := 0
	for i := range leftSorted {
		totalDistance += int(math.Abs(float64(leftSorted[i] - rightSorted[i])))
	}
	return totalDistance
}

func main() {
	left, right := input.Parse("input/input.txt")
	result := calculateTotalDistance(left, right)
	println("Total distance:", result)
}

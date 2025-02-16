package main

import (
	"day-01/input"
	"sort"
)

func calculateTotalDistance(left, right []int) int {
	// Make copies to avoid modifying original slices
	leftSorted := make([]int, len(left))
	rightSorted := make([]int, len(right))
	copy(leftSorted, left)
	copy(rightSorted, right)

	// Sort both lists
	sort.Ints(leftSorted)
	sort.Ints(rightSorted)

	// Calculate total distance
	totalDistance := 0
	for i := 0; i < len(leftSorted); i++ {
		distance := leftSorted[i] - rightSorted[i]
		if distance < 0 {
			distance = -distance
		}
		totalDistance += distance
	}

	return totalDistance
}

func main() {
	left, right := input.Parse("input/input.txt")
	result := calculateTotalDistance(left, right)
	println("Total distance:", result)
}

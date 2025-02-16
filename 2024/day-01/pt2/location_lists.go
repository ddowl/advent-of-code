package main

import (
	"day-01/input"
)

func calculateSimilarityScore(left, right []int) int {
	// Count occurrences of numbers in right list
	rightCounts := make(map[int]int)
	for _, num := range right {
		rightCounts[num]++
	}

	// Calculate similarity score
	totalScore := 0
	for _, leftNum := range left {
		// Multiply each left number by its occurrences in right list
		totalScore += leftNum * rightCounts[leftNum]
	}

	return totalScore
}

func main() {
	left, right := input.Parse("input/input.txt")
	result := calculateSimilarityScore(left, right)
	println("Similarity score:", result)
}

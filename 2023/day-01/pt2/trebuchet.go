package main

import (
	"aoc/day-01/input"
	"fmt"
	"unicode"
)

func calibrationValue(s string) int {
	firstDigit := 0
	lastDigit := 0
	for _, c := range s {
		if unicode.IsDigit(c) {
			if firstDigit == 0 {
				firstDigit = int(c - '0')
			}
			lastDigit = int(c - '0')
		}
	}
	return 10*firstDigit + lastDigit
}

func main() {
	lines, err := input.ReadPuzzleInput()
	if err != nil {
		fmt.Println(err)
		return
	}

	calibrationValueSum := 0
	for _, line := range lines {
		calibrationValueSum += calibrationValue(line)
	}
	fmt.Println("calibrationValueSum: ", calibrationValueSum)
}

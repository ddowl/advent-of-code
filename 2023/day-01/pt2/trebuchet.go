package main

import (
	"aoc/day-01/input"
	"fmt"
	"unicode"
)

var SpelledDigits = map[string]int{
	"one":   1,
	"two":   2,
	"three": 3,
	"four":  4,
	"five":  5,
	"six":   6,
	"seven": 7,
	"eight": 8,
	"nine":  9,
}

func spelledDigit(s string, idx int) *int {
	for key, value := range SpelledDigits {
		if len(s)-idx >= len(key) {
			slice := s[idx:(idx + len(key))]
			if slice == key {
				return &value
			}
		}
	}
	return nil
}

func calibrationValue(s string) int {
	firstDigit := 0
	lastDigit := 0
	for i, c := range s {
		if unicode.IsDigit(c) {
			if firstDigit == 0 {
				firstDigit = int(c - '0')
			}
			lastDigit = int(c - '0')
		} else if digit := spelledDigit(s, i); digit != nil {
			if firstDigit == 0 {
				firstDigit = *digit
			}
			lastDigit = *digit
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

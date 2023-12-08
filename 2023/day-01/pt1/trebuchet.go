package main

import (
	"aoc/day-01/input"
	"fmt"
	"regexp"
	"strconv"
)

var DigitRegex = regexp.MustCompile("[0-9]")

func calibrationValue(s string) (int, error) {
	digits := DigitRegex.FindAllString(s, -1)
	if len(digits) == 0 {
		return 0, nil
	}
	firstLast := fmt.Sprintf("%s%s", digits[0], digits[len(digits)-1])
	cv, err := strconv.Atoi(firstLast)
	if err != nil {
		return -1, err
	}
	return cv, nil
}

func main() {
	lines, err := input.ReadPuzzleInput()
	if err != nil {
		fmt.Println(err)
		return
	}

	calibrationValueSum := 0
	for _, line := range lines {
		cv, err := calibrationValue(line)
		if err != nil {
			fmt.Println(err)
			return
		}
		calibrationValueSum += cv
	}
	fmt.Println("calibrationValueSum: ", calibrationValueSum)
}

package main

import (
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
)

var DigitRegex = regexp.MustCompile("[0-9]")

func readFile(filename string) ([]string, error) {
	content, err := os.ReadFile(filename) // the file is inside the local directory
	if err != nil {
		return nil, err
	}
	return strings.Split(string(content), "\n"), nil
}

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
	lines, err := readFile("input.txt")
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

package main

import (
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
)

var DigitRegex = regexp.MustCompile("[0-9]")

func readFile(filename string) []string {
	content, err := os.ReadFile(filename) // the file is inside the local directory
	if err != nil {
		fmt.Println("Err")
	}
	return strings.Split(string(content), "\n")
}

func calibrationValue(s string) int {
	digits := DigitRegex.FindAllString(s, -1)
	if len(digits) == 0 {
		return 0
	}
	firstLast := fmt.Sprintf("%s%s", digits[0], digits[len(digits)-1])
	fmt.Println(digits)
	cv, err := strconv.Atoi(firstLast)
	if err != nil {
		panic(err)
		// fmt.Println(err)
	}
	return cv
}

func main() {
	lines := readFile("input.txt")
	calibrationValueSum := 0
	for _, line := range lines {
		calibrationValueSum += calibrationValue(line)
	}
	fmt.Println("calibrationValueSum: ", calibrationValueSum)
}

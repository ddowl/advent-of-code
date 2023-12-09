package input

import (
	"os"
	"strconv"
	"strings"
)

type Game struct {
	ID      int
	Reveals [][]CubeData
}

type CubeData struct {
	Num   int
	Color string
}

func readPuzzle(filename string) ([]Game, error) {
	content, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	lines := strings.Split(string(content), "\n")
	games := make([]Game, len(lines))
	splitInTwo := func(s string, delim string) (string, string) {
		substrs := strings.Split(s, delim)
		return substrs[0], substrs[1]
	}

	for i, line := range lines {
		gameIdStr, gameDetailsStr := splitInTwo(line, ":")
		id, err := strconv.Atoi(strings.Split(gameIdStr, " ")[1])
		if err != nil {
			return nil, err
		}

		reveals := make([][]CubeData, 0)

		revealSetStrs := strings.Split(gameDetailsStr, ";")
		for _, revealSetStr := range revealSetStrs {
			cubeDataStrs := strings.Split(revealSetStr, ", ")
			cubeDatas := make([]CubeData, 0)
			for _, cubeDataStr := range cubeDataStrs {
				numStr, colorStr := splitInTwo(strings.TrimSpace(cubeDataStr), " ")
				numCubes, err := strconv.Atoi(numStr)
				if err != nil {
					return nil, err
				}
				cubeDatas = append(cubeDatas, CubeData{Num: numCubes, Color: colorStr})
			}
			reveals = append(reveals, cubeDatas)
		}

		games[i] = Game{ID: id, Reveals: reveals}
	}
	return games, nil
}

func ReadPuzzle() ([]Game, error) {
	return readPuzzle("input/input.txt")
}

func ReadPuzzleTest() ([]Game, error) {
	return readPuzzle("input/test.txt")
}

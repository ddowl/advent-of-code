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
	for i, line := range lines {
		substrs := strings.Split(line, ":")
		id, err := strconv.Atoi(strings.Split(substrs[0], " ")[1])
		if err != nil {
			return nil, err
		}

		revealsStr := substrs[1]
		reveals := make([][]CubeData, 0)

		revealSetStrs := strings.Split(revealsStr, ";")
		for _, revealSetStr := range revealSetStrs {
			cubeDataStrs := strings.Split(revealSetStr, ", ")
			cubeDatas := make([]CubeData, 0)
			for _, cubeDataStr := range cubeDataStrs {
				cubeDataSubstrs := strings.Split(strings.TrimSpace(cubeDataStr), " ")
				numCubes, err := strconv.Atoi(cubeDataSubstrs[0])
				if err != nil {
					return nil, err
				}
				cubeDatas = append(cubeDatas, CubeData{Num: numCubes, Color: cubeDataSubstrs[1]})
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

package main

import (
	"aoc/day-08/input"
	"fmt"

	"github.com/samber/lo"
)

func main() {
	network := input.Parse("input/input.txt")
	// fmt.Printf("%+v\n", network)

	router := map[string][]string{}
	for _, node := range network.Nodes {
		router[node.Src] = []string{node.Left, node.Right}
	}
	// fmt.Printf("%+v\n", router)

	currNode := "AAA"
	for steps := 0; true; steps++ {
		if currNode == "ZZZ" {
			fmt.Printf("Found ZZZ after %d steps\n", steps)
			break
		}
		instruction := string(network.Instructions[steps%len(network.Instructions)])
		currNode = router[currNode][lo.Ternary(instruction == "L", 0, 1)]
	}
}

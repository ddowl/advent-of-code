package main

import (
	"aoc/day-08/input"
	"fmt"
	"strings"

	"github.com/samber/lo"
)

type Cycle struct {
	initStepsToTerminal  int
	stepsToCycleTerminal int
	seen                 map[string]bool
	cycleNode            string
	stepsToCycle         int
}

func main() {
	network := input.Parse("input/input.txt")

	router := map[string][]string{}
	for _, node := range network.Nodes {
		router[node.Src] = []string{node.Left, node.Right}
	}

	startingNodes := lo.FilterMap(network.Nodes, func(node input.Node, _ int) (string, bool) {
		return node.Src, strings.HasSuffix(node.Src, "A")
	})

	currNodes := make([]string, len(startingNodes))
	copy(currNodes, startingNodes)

	nodeCycles := make([]Cycle, len(currNodes))
	for i := range nodeCycles {
		nodeCycles[i] = Cycle{0, 0, map[string]bool{}, "", 0}
	}

	for steps := 0; true; steps++ {
		for i := range currNodes {
			node := currNodes[i]
			// cycle := nodeCycles[i]
			if strings.HasSuffix(node, "Z") {
				if nodeCycles[i].initStepsToTerminal == 0 {
					nodeCycles[i].initStepsToTerminal = steps
				} else {
					nodeCycles[i].stepsToCycleTerminal = steps - nodeCycles[i].initStepsToTerminal
				}
			}

			if nodeCycles[i].seen[node] && nodeCycles[i].stepsToCycle == 0 {
				nodeCycles[i].stepsToCycle = steps
				nodeCycles[i].cycleNode = node
			}
		}

		if lo.EveryBy(nodeCycles, func(cycle Cycle) bool {
			return cycle.stepsToCycleTerminal != 0
		}) {
			break
		}

		// if lo.EveryBy(currNodes, func(node string) bool {
		// 	return strings.HasSuffix(node, "Z")
		// }) {
		// 	break
		// }

		instruction := string(network.Instructions[steps%len(network.Instructions)])
		for i := range currNodes {
			nodeCycles[i].seen[currNodes[i]] = true
			currNodes[i] = router[currNodes[i]][lo.Ternary(instruction == "L", 0, 1)]
		}
	}
	fmt.Printf("%+v\n", nodeCycles)
}

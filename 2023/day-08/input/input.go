package input

import (
	"os"
	"strings"

	"github.com/samber/lo"
)

type Network struct {
	Instructions string
	Nodes        []Node
}

type Node struct {
	Src   string
	Left  string
	Right string
}

func splitInTwo(s string, delim string) (string, string) {
	ss := strings.Split(s, delim)
	return ss[0], ss[1]
}

func Parse(filename string) *Network {
	contents, err := os.ReadFile(filename)
	if err != nil {
		panic(err)
	}

	instructions, body := splitInTwo(string(contents), "\n\n")

	nodes := lo.Map(strings.Split(body, "\n"), func(nodeStr string, _ int) Node {
		src, neighborsStr := splitInTwo(nodeStr, " = ")
		left, right := splitInTwo(strings.Trim(neighborsStr, "()"), ", ")
		return Node{src, left, right}
	})
	return &Network{instructions, nodes}
}

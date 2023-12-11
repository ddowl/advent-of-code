package main

import (
	"aoc/day-07/input"
	"fmt"
	"slices"
	"strings"

	"github.com/samber/lo"
)

type HandType int

const (
	HighCard HandType = iota
	OnePair
	TwoPairs
	ThreeOfAKind
	FullHouse
	FourOfAKind
	FiveOfAKind
)

var CardStrength = map[string]int{
	"A": 14,
	"K": 13,
	"Q": 12,
	"T": 10,
	"9": 9,
	"8": 8,
	"7": 7,
	"6": 6,
	"5": 5,
	"4": 4,
	"3": 3,
	"2": 2,
	"J": 1,
}

type Hand struct {
	Cards    string
	Bid      int
	Type     HandType
	Strength []int
}

func handType(cards map[string]int) HandType {
	jokers := cards["J"]
	delete(cards, "J")

	countOfEachCard := lo.Reject(lo.Values(cards), func(n int, _ int) bool { return n == 0 })
	if len(countOfEachCard) == 0 {
		return FiveOfAKind
	}
	slices.Sort(countOfEachCard)
	slices.Reverse(countOfEachCard)
	countOfEachCard[0] += jokers

	if lo.Contains(countOfEachCard, 5) {
		return FiveOfAKind
	} else if lo.Contains(countOfEachCard, 4) {
		return FourOfAKind
	} else if lo.Contains(countOfEachCard, 3) && lo.Contains(countOfEachCard, 2) {
		return FullHouse
	} else if lo.Contains(countOfEachCard, 3) {
		return ThreeOfAKind
	} else if lo.Contains(countOfEachCard, 2) {
		if lo.Count(countOfEachCard, 2) == 2 {
			return TwoPairs
		}
		return OnePair
	}
	return HighCard
}

func main() {
	inputHands, err := input.Parse()
	if err != nil {
		panic(err)
	}

	hands := lo.Map(inputHands, func(hand input.Hand, _ int) Hand {
		cardCount := lo.Reduce(strings.Split(hand.Cards, ""), func(acc map[string]int, card string, _ int) map[string]int {
			acc[card]++
			return acc
		}, map[string]int{
			"A": 0,
			"K": 0,
			"Q": 0,
			"J": 0,
			"T": 0,
			"9": 0,
			"8": 0,
			"7": 0,
			"6": 0,
			"5": 0,
			"4": 0,
			"3": 0,
			"2": 0,
		})

		return Hand{
			Cards: hand.Cards,
			Bid:   hand.Bid,
			Type:  handType(cardCount),
			Strength: lo.Map(strings.Split(hand.Cards, ""), func(card string, _ int) int {
				return CardStrength[card]
			}),
		}
	})

	slices.SortFunc(hands, func(a Hand, b Hand) int {
		if a.Type != b.Type {
			return int(a.Type) - int(b.Type)
		}
		for i := 0; i < len(a.Strength); i++ {
			if a.Strength[i] != b.Strength[i] {
				return a.Strength[i] - b.Strength[i]
			}
		}
		return 0
	})

	winnings := 0
	for i := 0; i < len(hands); i++ {
		winnings += (i + 1) * hands[i].Bid
	}
	fmt.Println(winnings)
}

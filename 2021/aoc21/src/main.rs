use std::collections::HashMap;
use std::fmt::{Debug, Formatter};
use std::fs;

#[macro_use]
extern crate lazy_static;

lazy_static! {
    static ref ROLL_FREQUENCY: HashMap<usize, usize> =
        HashMap::from([(3, 1), (4, 3), (5, 6), (6, 7), (7, 6), (8, 3), (9, 1)]);
    static ref POSSIBLE_DICE_ROLLS: Vec<(usize, usize, usize)> = (1..=3)
        .flat_map(|i| (1..=3).flat_map(move |j| (1..=3).map(move |k| (i, j, k))))
        .collect();
}

#[derive(PartialEq, Eq, Hash, Clone)]
struct DiracDiceGame {
    pawns: [usize; 2],
    scores: [usize; 2],
    current_player: usize, // Rust why tf can't i make a union type of usize literals -> 0 | 1
}

impl DiracDiceGame {
    fn new(initial_pawn_positions: [usize; 2]) -> Self {
        DiracDiceGame {
            pawns: initial_pawn_positions,
            scores: [0, 0],
            current_player: 0,
        }
    }

    fn play_next_turn(&self, advance_by: usize) -> Self {
        let pawn_position = self.pawns[self.current_player];
        let next_position = ((pawn_position + advance_by - 1) % 10) + 1;

        let mut next_pawns = self.pawns;
        let mut next_scores = self.scores;

        next_pawns[self.current_player] = next_position;
        next_scores[self.current_player] += next_position;

        DiracDiceGame {
            pawns: next_pawns,
            scores: next_scores,
            current_player: if self.current_player == 0 { 1 } else { 0 },
        }
    }

    fn count_wins(&self) -> [usize; 2] {
        let mut cache = HashMap::new();
        self.count_wins_helper(&mut cache)
    }

    fn count_wins_helper(&self, cache: &mut HashMap<DiracDiceGame, [usize; 2]>) -> [usize; 2] {
        // if in winning state, report winner and loser
        if self.scores[0] >= 21 {
            [1, 0]
        } else if self.scores[1] >= 21 {
            [0, 1]
        } else if let Some(cached_wins) = cache.get(self) {
            *cached_wins
        } else {
            // otherwise explore possible futures, sum win states for each future
            // let wins = ROLL_FREQUENCY
            //     .iter()
            //     .map(|(advance_by, num_futures)| {
            //         let mut future_wins = self.play_next_turn(*advance_by).count_wins_helper(cache);
            //         // this possible future will occur num_futures times
            //         future_wins[self.current_player] *= num_futures;
            //         future_wins
            //     })
            //     .reduce(|acc, wins| [acc[0] + wins[0], acc[1] + wins[1]])
            //     .unwrap();

            let wins = POSSIBLE_DICE_ROLLS
                .iter()
                .map(|(i, j, k)| self.play_next_turn(i + j + k).count_wins_helper(cache))
                .reduce(|acc, wins| [acc[0] + wins[0], acc[1] + wins[1]])
                .unwrap();

            // cache in case we hit this state in other branches
            cache.insert(self.clone(), wins);
            wins
        }
    }
}

impl Debug for DiracDiceGame {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("DiracDiceGame")
            .field("pawns", &self.pawns)
            .field("scores", &self.scores)
            .field("current_player", &self.current_player)
            .finish()
    }
}

fn main() {
    let filename = "input/input.txt";
    let pawn_positions = parse_input_file(filename);

    println!("pawn_positions: {:?}", pawn_positions);
    println!();

    // Part 1

    let mut dice_game = DiracDiceGame::new(pawn_positions);

    let mut die = deterministic_die();
    let mut num_dice_rolls = 0;
    while dice_game.scores.iter().all(|s| *s < 1000) {
        // for _ in (0..1) {
        let advance_by = (0..3).map(|_| die.next().unwrap()).sum();
        num_dice_rolls += 3;
        dice_game = dice_game.play_next_turn(advance_by);
    }

    println!("end state: {:?}", dice_game);

    let losing_score = dice_game.scores[dice_game.current_player];
    let part1 = num_dice_rolls * losing_score;
    println!("part1 answer: {}", part1);

    // Part 2

    dice_game = DiracDiceGame::new(pawn_positions);
    let wins = dice_game.count_wins();
    println!("wins: {:?}", wins);
}

fn deterministic_die() -> impl Iterator<Item = usize> {
    (1..=100).cycle()
}

fn parse_input_file(filename: &str) -> [usize; 2] {
    let file_contents = fs::read_to_string(filename).unwrap();
    let lines: Vec<String> = file_contents.split("\n").map(|s| s.to_string()).collect();
    assert_eq!(lines.len(), 2);
    let get_starting_pawn = |i: usize| {
        lines[i].split(": ").collect::<Vec<&str>>()[1]
            .parse()
            .unwrap()
    };
    [get_starting_pawn(0), get_starting_pawn(1)]
}

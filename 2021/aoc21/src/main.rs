use std::fmt::{Debug, Formatter};
use std::fs;

struct DiracDiceGame {
    pawns: [usize; 2],
    scores: [usize; 2],
    current_player: usize, // Rust why tf can't i make a union type of usize literals -> 0 | 1
    num_turns_played: usize,
    die: Box<dyn Iterator<Item = usize>>,
}

impl DiracDiceGame {
    fn new(initial_pawn_positions: [usize; 2], die: Box<dyn Iterator<Item = usize>>) -> Self {
        DiracDiceGame {
            pawns: initial_pawn_positions,
            scores: [0, 2],
            current_player: 0,
            num_turns_played: 0,
            die,
        }
    }

    fn play_next_turn(&mut self) {
        let advance_by: usize = (0..3).map(|_| self.die.next().unwrap()).sum();

        let pawn_position = self.pawns[self.current_player];
        let next_position = ((pawn_position + advance_by - 1) % 10) + 1;

        self.pawns[self.current_player] = next_position;
        self.scores[self.current_player] += next_position;
        self.current_player = if self.current_player == 0 { 1 } else { 0 };
        self.num_turns_played += 1;
    }
}

impl Debug for DiracDiceGame {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("DiracDiceGame")
            .field("pawns", &self.pawns)
            .field("scores", &self.scores)
            .field("current_player", &self.current_player)
            .field("num_turns_played", &self.num_turns_played)
            .finish()
    }
}

fn main() {
    let filename = "input/input.txt";
    let mut pawn_positions = parse_input_file(filename);

    println!("pawn_positions: {:?}", pawn_positions);
    println!();

    let mut dice_game = DiracDiceGame::new(pawn_positions, Box::new(deterministic_dice()));

    while dice_game.scores.iter().all(|s| *s < 1000) {
        dice_game.play_next_turn();
    }

    println!("end state: {:?}", dice_game);

    let num_dice_rolls = dice_game.num_turns_played * 3;
    let losing_score = dice_game.scores[dice_game.current_player];
    let part1 = num_dice_rolls * losing_score;
    println!("part1 answer: {}", part1);
}

fn deterministic_dice() -> impl Iterator<Item = usize> {
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

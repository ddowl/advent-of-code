use std::fs::File;
use std::io::{BufRead, BufReader};

#[derive(Eq, PartialEq)]
enum Direction {
    Forward,
    Up,
    Down,
}

fn main() {
    let filename = "input/test.txt";
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).unwrap();
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    // TODO: Can I propagate validation errors as a `Result<Vec<Direction, i32>>`?
    let instructions: Vec<(Direction, i32)> = reader
        .lines()
        .enumerate()
        .map(|(_idx, line_res)| {
            let line = line_res.expect("couldn't read line!");
            let tokens: Vec<&str> = line.split(" ").collect();
            let direction: Direction = match tokens[0] {
                "forward" => Direction::Forward,
                "up" => Direction::Up,
                "down" => Direction::Down,
                x => panic!("invalid direction: {}", x),
            };
            (direction, tokens[1].parse().unwrap())
        })
        .collect();

    // println!("{:?}", instructions);

    // Part 1
    let distance = count_distance(&instructions);
    let depth = count_depth(&instructions);
    println!("distance {}", distance);
    println!("depth {}", depth);
    println!("product {}", distance * depth);
}

fn count_distance(instructions: &Vec<(Direction, i32)>) -> i32 {
    instructions
        .iter()
        .filter(|(dir, _)| dir == &Direction::Forward)
        .map(|(_, mag)| mag)
        .sum()
}

fn count_depth(instructions: &Vec<(Direction, i32)>) -> i32 {
    instructions
        .iter()
        .map(|(dir, mag)| match dir {
            Direction::Forward => 0,
            Direction::Up => -mag,
            Direction::Down => *mag,
        })
        .sum()
}

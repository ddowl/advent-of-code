use std::error::Error;
use std::fs::File;
use std::io::{BufRead, BufReader};

#[derive(Eq, PartialEq)]
enum Direction {
    Forward,
    Up,
    Down,
}

type ParseResult<T> = Result<T, Box<dyn Error>>;

fn main() {
    let filename = "input/input.txt";
    let result: ParseResult<Vec<(Direction, i32)>> = parse_input_file(filename);
    match result {
        Err(e) => {
            println!("Error parsing input file: {}", e);
        }

        Ok(instructions) => {
            // println!("{:?}", instructions);

            // Part 1
            let distance = count_distance(&instructions);
            let depth = count_depth(&instructions);
            println!("distance {}", distance);
            println!("depth {}", depth);
            println!("product {}", distance * depth);

            // Part 2
            let (distance, depth) = count_with_aim(&instructions);
            println!("distance {}", distance);
            println!("depth {}", depth);
            println!("product {}", distance * depth);
        }
    }
}

fn parse_input_file(filename: &str) -> ParseResult<Vec<(Direction, i32)>> {
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename)?;
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    reader
        .lines()
        .enumerate()
        .map(|(_, line_res)| {
            let line = line_res?; // `line` needs to live till end of the closure
            let tokens: Vec<&str> = line.split(" ").collect();
            let direction: Direction = match tokens[0] {
                "forward" => Direction::Forward,
                "up" => Direction::Up,
                "down" => Direction::Down,
                x => return Err(format!("invalid direction: {}", x).into()),
            };
            let magnitude = tokens[1].parse()?;
            Ok((direction, magnitude))
        })
        .collect()
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

fn count_with_aim(instructions: &Vec<(Direction, i32)>) -> (i32, i32) {
    let (distance, depth, _mag) = instructions.iter().fold(
        (0, 0, 0),
        |(curr_distance, curr_depth, curr_aim), (dir, mag)| match dir {
            Direction::Down => (curr_distance, curr_depth, curr_aim + mag),
            Direction::Up => (curr_distance, curr_depth, curr_aim - mag),
            Direction::Forward => (curr_distance + mag, curr_depth + (curr_aim * mag), curr_aim),
        },
    );

    (distance, depth)
}

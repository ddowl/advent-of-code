use std::fs::File;
use std::io::{BufRead, BufReader};

fn main() {
    let filename = "input/test.txt";
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).unwrap();
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    let instructions: Vec<(String, i32)> = reader
        .lines()
        .enumerate()
        .map(|(_idx, line_res)| {
            let line = line_res.expect("couldn't read line!");
            let tokens: Vec<&str> = line.split(" ").collect();
            (tokens[0].to_string(), tokens[1].parse().unwrap())
        })
        .collect();

    // println!("{:?}", instructions);

    let horizontal_distance = count_horizontal(&instructions);
    let depth = count_depth(&instructions);
    println!("horizontal {}", horizontal_distance);
    println!("depth {}", depth);
    println!("product {}", horizontal_distance * depth);
}

fn count_horizontal(instructions: &Vec<(String, i32)>) -> i32 {
    instructions
        .iter()
        .filter(|(dir, _)| dir == "forward")
        .map(|(_, mag)| mag)
        .sum()
}

fn count_depth(instructions: &Vec<(String, i32)>) -> i32 {
    instructions
        .iter()
        .map(|(dir, mag)| match dir.as_str() {
            "down" => *mag,
            "up" => -mag,
            _ => 0,
        })
        .sum()
}

use std::fs::File;
use std::io::{BufRead, BufReader};

fn main() {
    let filename = "input/input.txt";
    let mut fish: Vec<u8> = parse_input_file(filename);

    println!("fish: {:?}", fish);
    println!();

    let num_days = 80;
    (0..num_days).for_each(|d| {
        println!("day {}", d);
        advance_day(&mut fish);
    });

    println!("num fish after {} days: {:?}", num_days, fish.len());
}

fn advance_day(fish: &mut Vec<u8>) {
    let mut num_new_fish = 0;
    for i in 0..fish.len() {
        if fish[i] == 0 {
            num_new_fish += 1;
            fish[i] = 6;
        } else {
            fish[i] -= 1;
        }
    }

    for _ in 0..num_new_fish {
        fish.push(8)
    }
}

fn parse_input_file(filename: &str) -> Vec<u8> {
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).expect("couldn't open file");
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    reader
        .lines()
        .nth(0)
        .unwrap()
        .unwrap()
        .split(",")
        .map(|n| n.parse().unwrap())
        .collect()
}

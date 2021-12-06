use std::fs::File;
use std::io::{BufRead, BufReader};
use std::time::Instant;

fn main() {
    let filename = "input/input.txt";
    let fish: Vec<u8> = parse_input_file(filename);

    println!("fish: {:?}", fish);
    println!();

    let mut fish_reproduction_schedule: [usize; 9] = [0; 9];
    fish.iter()
        .for_each(|days_left| fish_reproduction_schedule[usize::from(*days_left)] += 1);

    let num_days = 256;
    let mut last_time = Instant::now();
    (0..num_days).for_each(|d| {
        // advance_day(&mut fish);
        advance_day(&mut fish_reproduction_schedule);
        let time_to_advance = Instant::now() - last_time;
        println!("day {} in {:?}", d, time_to_advance);
        last_time = Instant::now();
    });

    println!(
        "num fish after {} days: {:?}",
        num_days,
        fish_reproduction_schedule.iter().sum::<usize>()
    );
}

fn advance_day(fish_reproduction_schedule: &mut [usize; 9]) {
    // save new fish for today
    let num_new_fish = fish_reproduction_schedule[0];

    // "decrement" fish in each bucket
    for i in 0..8 {
        fish_reproduction_schedule[i] = fish_reproduction_schedule[i + 1];
    }

    // add in new fish into buckets for 6 & 8 days left
    fish_reproduction_schedule[6] += num_new_fish;
    fish_reproduction_schedule[8] = num_new_fish;
}

// fn advance_day(fish: &mut Vec<u8>) {
//     let mut num_new_fish = 0;
//     for i in 0..fish.len() {
//         if fish[i] == 0 {
//             num_new_fish += 1;
//             fish[i] = 6;
//         } else {
//             fish[i] -= 1;
//         }
//     }
//
//     for _ in 0..num_new_fish {
//         fish.push(8)
//     }
// }

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

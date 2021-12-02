use std::fs::File;
use std::io::{BufRead, BufReader};

fn main() {
    let filename = "input/input.txt";
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).unwrap();
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    let depths: Vec<usize> = reader
        .lines()
        .enumerate()
        .map(|(_idx, line)| line.expect("couldn't read string!").parse().unwrap())
        .collect();

    println!("depth_increases: {}", depth_increases(&depths, 1));
    println!(
        "depth_increases with sliding window: {}",
        depth_increases(&depths, 3)
    )
}

fn depth_increases(depths: &Vec<usize>, window: usize) -> usize {
    let sliding_window_sums: Vec<usize> = depths
        .windows(window)
        .map(|window_of_depths| window_of_depths.iter().sum())
        .collect();

    let mut curr_depth = sliding_window_sums[0];
    let mut num_increases: usize = 0;
    for depth in sliding_window_sums[1..].iter() {
        if *depth > curr_depth {
            num_increases += 1;
        }
        curr_depth = *depth;
    }
    num_increases
}

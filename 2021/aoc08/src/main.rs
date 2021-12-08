use std::fs::File;
use std::io::{BufRead, BufReader};

type Display = ([String; 10], [String; 4]);

fn main() {
    let filename = "input/input.txt";
    let displays: Vec<Display> = parse_input_file(filename);

    println!("displays: {:?}", displays);
    println!();

    let unique_segment_counts = vec![2, 3, 4, 7];

    let num_digits_with_unique_segment_count = displays
        .iter()
        .map(|(_, digits)| {
            digits
                .iter()
                .filter(|&d| unique_segment_counts.contains(&d.len()))
        })
        .flatten()
        .count();

    println!(
        "num_digits_with_unique_segment_count: {}",
        num_digits_with_unique_segment_count
    );
}

fn parse_input_file(filename: &str) -> Vec<Display> {
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).expect("couldn't open file");
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    reader
        .lines()
        .map(|l| {
            let line = l.unwrap();
            let parts: Vec<&str> = line.split(" | ").collect();
            assert_eq!(parts.len(), 2);
            let digit_combinations: [String; 10] = into_array(parts[0]);
            let four_digit_display: [String; 4] = into_array(parts[1]);
            (digit_combinations, four_digit_display)
        })
        .collect()
}

fn into_array<const N: usize>(s: &str) -> [String; N] {
    s.split_whitespace()
        .map(<str>::to_string)
        .collect::<Vec<String>>()
        .try_into()
        .unwrap()
}

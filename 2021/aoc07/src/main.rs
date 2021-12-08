use std::fs::File;
use std::io::{BufRead, BufReader};

fn main() {
    let filename = "input/input.txt";
    let crab_positions: Vec<u16> = parse_input_file(filename);

    println!("crab_positions: {:?}", crab_positions);
    println!();

    // cost increases monotonically away from optimal target position.
    // can't use binary search with rotation because costs aren't sorted.
    // any way to search the space faster than linear?

    let (target_pos, fuel_cost) = min_target_pos_and_cost(&crab_positions);
    println!(
        "min cost target: {}, min fuel cost: {}",
        target_pos, fuel_cost
    );
}

fn min_target_pos_and_cost(crab_positions: &Vec<u16>) -> (u16, usize) {
    let max_pos = *crab_positions.iter().max().unwrap();
    (0..=max_pos)
        .into_iter()
        .map(|target_pos| (target_pos, alignment_cost(crab_positions, target_pos)))
        .min_by(|(_, cost_a), (_, cost_b)| cost_a.cmp(cost_b))
        .unwrap()
}

fn alignment_cost(crab_positions: &Vec<u16>, target_position: u16) -> usize {
    let target_pos_int = isize::try_from(target_position).unwrap();
    usize::try_from(
        crab_positions
            .iter()
            .map(|p| (target_pos_int - isize::try_from(*p).unwrap()).abs())
            .sum::<isize>(),
    )
    .unwrap()
}

fn parse_input_file(filename: &str) -> Vec<u16> {
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

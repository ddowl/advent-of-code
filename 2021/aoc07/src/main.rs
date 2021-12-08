use std::fs::File;
use std::io::{BufRead, BufReader};

type CostFn = fn(pos_a: isize, pos_b: isize) -> usize;

fn main() {
    let filename = "input/input.txt";
    let crab_positions: Vec<u16> = parse_input_file(filename);

    println!("crab_positions: {:?}", crab_positions);
    println!();

    // cost increases monotonically away from optimal target position.
    // can't use binary search with rotation because costs aren't sorted.
    // any way to search the space faster than linear?

    // Part 1
    let (target_pos, fuel_cost) = min_target_pos_and_cost(&crab_positions, constant_fuel_cost);
    println!(
        "Constant Fuel Cost Rate: min cost target: {}, min fuel cost: {}",
        target_pos, fuel_cost
    );

    // Part 2
    let (target_pos, fuel_cost) = min_target_pos_and_cost(&crab_positions, linear_cost_rate);
    println!(
        "Linear Fuel Cost Rate: min cost target: {}, min fuel cost: {}",
        target_pos, fuel_cost
    );
}

fn min_target_pos_and_cost(crab_positions: &Vec<u16>, cost_fn: CostFn) -> (u16, usize) {
    let max_pos = *crab_positions.iter().max().unwrap();
    (0..=max_pos)
        .into_iter()
        .map(|target_pos| {
            (
                target_pos,
                alignment_cost(crab_positions, target_pos, cost_fn),
            )
        })
        .min_by(|(_, cost_a), (_, cost_b)| cost_a.cmp(cost_b))
        .unwrap()
}

fn alignment_cost(crab_positions: &Vec<u16>, target_position: u16, cost_fn: CostFn) -> usize {
    let target_pos_int = isize::try_from(target_position).unwrap();
    crab_positions
        .iter()
        .map(|p| cost_fn(target_pos_int, isize::try_from(*p).unwrap()))
        .sum()
}

fn constant_fuel_cost(pos_a: isize, pos_b: isize) -> usize {
    usize::try_from((pos_a - pos_b).abs()).unwrap()
}

fn linear_cost_rate(pos_a: isize, pos_b: isize) -> usize {
    triangle(constant_fuel_cost(pos_a, pos_b))
}

// https://en.wikipedia.org/wiki/Triangular_number
fn triangle(n: usize) -> usize {
    n * (n + 1) / 2
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

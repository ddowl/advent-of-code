use itertools::Itertools;
use std::fs;
use std::ops::RangeInclusive;

type Position = (isize, isize);
type Velocity = (isize, isize);
type Area = (RangeInclusive<isize>, RangeInclusive<isize>);
type KineticState = (Position, Velocity);

fn within_area((x_range, y_range): &Area, (x, y): &Position) -> bool {
    x_range.contains(x) && y_range.contains(y)
}

fn past_area((x_range, y_range): &Area, (x, y): &Position) -> bool {
    x > x_range.end() || y < y_range.start()
}

fn step(((x_pos, y_pos), (x_vel, y_vel)): &mut KineticState) {
    //  The probe's x position increases by its x velocity.
    //  The probe's y position increases by its y velocity.
    //  Due to drag, the probe's x velocity changes by 1 toward the value 0; that is, it decreases by 1 if it is greater than 0, increases by 1 if it is less than 0, or does not change if it is already 0.
    //  Due to gravity, the probe's y velocity decreases by 1.

    *x_pos += *x_vel;
    *y_pos += *y_vel;
    *x_vel += 0.cmp(x_vel) as isize;
    *y_vel -= 1;
}

fn launch_probe(area: &Area, mut state: KineticState) -> bool {
    while !past_area(&area, &state.0) {
        if within_area(&area, &state.0) {
            return true;
        }
        step(&mut state);
    }
    false
}

fn main() {
    let filename = "input/input.txt";
    let target_area = parse_input_file(filename);

    println!("target_area: {:?}", target_area);
    println!();

    let max_y_vel = 1000;
    let accurate_initial_vels: Vec<Velocity> = (0..1000)
        .cartesian_product(-500..max_y_vel)
        .filter(|init_vel| launch_probe(&target_area, ((0, 0), *init_vel)))
        .collect();
    println!("accurate_initial_vels: {:?}", accurate_initial_vels);
    println!(
        "num accurate_initial_vels: {:?}",
        accurate_initial_vels.len()
    );
}

fn parse_input_file(filename: &str) -> Area {
    let file_contents = fs::read_to_string(filename).unwrap();
    let tokens: Vec<_> = file_contents
        .split_whitespace()
        .map(|s| s.to_string())
        .collect();
    let x_range: Vec<isize> = tokens[2][2..tokens[2].len() - 1]
        .split("..")
        .map(|n| n.parse().unwrap())
        .collect();
    let y_range: Vec<isize> = tokens[3][2..]
        .split("..")
        .map(|n| n.parse().unwrap())
        .collect();
    ((x_range[0]..=x_range[1]), (y_range[0]..=y_range[1]))
}

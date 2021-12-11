use std::collections::HashSet;
use std::fs::File;
use std::io::{BufRead, BufReader};

type Coordinate = (usize, usize);
type DumboOctopusEnergyLevels = [[u8; 10]; 10];

fn main() {
    let filename = "input/input.txt";
    let mut energy_levels: DumboOctopusEnergyLevels = parse_input_file(filename);

    println!("initial energy_levels: {:?}", energy_levels);
    println!();

    let num_steps = 100;
    let mut num_flashes: usize = 0;
    for _ in 0..num_steps {
        num_flashes += step(&mut energy_levels);
    }

    println!("num flashes after {} steps: {}", num_steps, num_flashes);
}

fn step(energy_levels: &mut DumboOctopusEnergyLevels) -> usize {
    // First, the energy level of each octopus increases by 1.
    energy_levels.iter_mut().for_each(|row| {
        row.iter_mut().for_each(|energy_level| {
            *energy_level += 1;
        })
    });

    // Then, any octopus with an energy level greater than 9 flashes.
    // This increases the energy level of all adjacent octopuses by 1, including octopuses that are diagonally adjacent.
    // If this causes an octopus to have an energy level greater than 9, it also flashes.
    // This process continues as long as new octopuses keep having their energy level increased beyond 9. (An octopus can only flash at most once per step.)
    let mut flashed: HashSet<Coordinate> = HashSet::new();
    let side_len = energy_levels.len();

    for x in 0..side_len {
        for y in 0..side_len {
            let curr_coord = (x, y);
            if flashed.contains(&curr_coord) {
                continue;
            }
            let curr_energy_level = energy_levels[x][y];
            if curr_energy_level > 9 {
                flash(energy_levels, &mut flashed, curr_coord);
            }
        }
    }

    // Finally, any octopus that flashed during this step has its energy level set to 0, as it used all of its energy to flash.
    for (x, y) in &flashed {
        energy_levels[*x][*y] = 0;
    }

    flashed.len()
}

// Mark current octopus as flashed
// Increase energy levels of surrounding octopuses
// Trigger flash on any neighbors if energy level is greater than 9 and they haven't already flashed
fn flash(
    energy_levels: &mut DumboOctopusEnergyLevels,
    flashed: &mut HashSet<Coordinate>,
    octo_coord: Coordinate,
) {
    flashed.insert(octo_coord);
    for neighbor_coord in neighboring_octopuses(octo_coord) {
        let (nx, ny) = neighbor_coord;
        energy_levels[nx][ny] += 1;
        if energy_levels[nx][ny] > 9 && !flashed.contains(&neighbor_coord) {
            flash(energy_levels, flashed, neighbor_coord);
        }
    }
}

fn neighboring_octopuses(c: Coordinate) -> Vec<Coordinate> {
    let (x, y) = c;
    let ix = isize::try_from(x).unwrap();
    let iy = isize::try_from(y).unwrap();

    vec![
        (ix - 1, iy),
        (ix + 1, iy),
        (ix, iy - 1),
        (ix, iy + 1),
        (ix - 1, iy - 1),
        (ix - 1, iy + 1),
        (ix + 1, iy - 1),
        (ix + 1, iy + 1),
    ]
    .into_iter()
    .filter(|c| in_bounds(c))
    .map(|(nx, ny)| (usize::try_from(nx).unwrap(), usize::try_from(ny).unwrap()))
    .collect()
}

fn in_bounds((x, y): &(isize, isize)) -> bool {
    (0..10).contains(x) && (0..10).contains(y)
}

fn parse_input_file(filename: &str) -> DumboOctopusEnergyLevels {
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).expect("couldn't open file");
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    reader
        .lines()
        .map(|l| {
            let line = l.unwrap();
            assert_eq!(line.len(), 10);
            <[u8; 10]>::try_from(
                line.chars()
                    .map(|c| c.to_string().parse().unwrap())
                    .collect::<Vec<u8>>(),
            )
            .unwrap()
        })
        .collect::<Vec<[u8; 10]>>()
        .try_into()
        .unwrap()
}

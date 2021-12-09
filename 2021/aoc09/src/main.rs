use itertools::Itertools;
use std::fs::File;
use std::io::{BufRead, BufReader};

type Heightmap = Vec<Vec<u8>>;

fn main() {
    let filename = "input/input.txt";
    let heightmap: Heightmap = parse_input_file(filename);

    println!("heightmap: {:?}", heightmap);
    println!();

    let low_points = find_low_points(&heightmap);
    println!("low points: {:?}", low_points);

    let risk_levels: Vec<usize> = low_points
        .iter()
        .map(|(x, y)| usize::from(heightmap[*x][*y] + 1))
        .collect();

    println!("risk levels: {:?}", risk_levels);
    println!(
        "sum of risk levels: {:?}",
        risk_levels.iter().sum::<usize>()
    );
}

fn find_low_points(heightmap: &Heightmap) -> Vec<(usize, usize)> {
    let num_rows = heightmap.len();
    let num_cols = heightmap[0].len();

    // can i do this without casting to ints for valid neighbor checks?
    let inum_rows = isize::try_from(num_rows).unwrap();
    let inum_cols = isize::try_from(num_cols).unwrap();

    let in_bounds = |(x, y): &(isize, isize)| -> bool {
        x >= &0 && x < &inum_rows && y >= &0 && y < &inum_cols
    };

    let is_low_point = |(x, y): (usize, usize)| -> bool {
        let curr_height = heightmap[x][y];

        let ix = isize::try_from(x).unwrap();
        let iy = isize::try_from(y).unwrap();

        let neighbor_coords: Vec<(usize, usize)> =
            vec![(ix - 1, iy), (ix + 1, iy), (ix, iy - 1), (ix, iy + 1)]
                .into_iter()
                .filter(in_bounds)
                .map(|(nx, ny)| (usize::try_from(nx).unwrap(), usize::try_from(ny).unwrap()))
                .collect();

        let neighbor_heights: Vec<u8> = neighbor_coords
            .into_iter()
            .map(|(nx, ny)| heightmap[nx][ny])
            .collect();

        curr_height < neighbor_heights.into_iter().min().unwrap()
    };

    (0..num_rows)
        .cartesian_product(0..num_cols)
        .filter(|coords| is_low_point(*coords))
        .collect()
}

fn parse_input_file(filename: &str) -> Heightmap {
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).expect("couldn't open file");
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    reader
        .lines()
        .map(|l| {
            l.unwrap()
                .chars()
                .map(|n| n.to_string().parse().unwrap())
                .collect()
        })
        .collect()
}

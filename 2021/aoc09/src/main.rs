use itertools::Itertools;
use std::collections::{BinaryHeap, HashSet};
use std::fs::File;
use std::io::{BufRead, BufReader};

type Coordinate = (usize, usize);
#[derive(Debug)]
struct Heightmap {
    grid: Vec<Vec<u8>>,
    num_rows: usize,
    num_cols: usize,
    inum_rows: isize,
    inum_cols: isize,
}

impl Heightmap {
    fn new(grid: Vec<Vec<u8>>) -> Heightmap {
        let num_rows = grid.len();
        let num_cols = grid[0].len();

        // can i do this without casting to ints for valid neighbor checks?
        let inum_rows = isize::try_from(num_rows).unwrap();
        let inum_cols = isize::try_from(num_cols).unwrap();

        Heightmap {
            grid,
            num_rows,
            num_cols,
            inum_rows,
            inum_cols,
        }
    }

    fn find_basins(&self, low_points: &Vec<Coordinate>) -> Vec<HashSet<Coordinate>> {
        // for each low point, explore around until encountering a 9 or edge
        low_points
            .into_iter()
            .map(|coord| {
                let mut basin_coords = HashSet::new();
                self.explore_basin(*coord, &mut basin_coords);
                basin_coords
            })
            .collect()
    }

    fn explore_basin(
        &self,
        curr_coordinate: Coordinate,
        basin_coordinates: &mut HashSet<Coordinate>,
    ) {
        if self.get_height(curr_coordinate) != 9 && !basin_coordinates.contains(&curr_coordinate) {
            basin_coordinates.insert(curr_coordinate);

            self.neighbor_coords(curr_coordinate)
                .into_iter()
                .for_each(|c| self.explore_basin(c, basin_coordinates));
        }
    }

    fn find_low_points(&self) -> Vec<(usize, usize)> {
        (0..self.num_rows)
            .cartesian_product(0..self.num_cols)
            .filter(|coords| self.is_low_point(*coords))
            .collect()
    }

    fn is_low_point(&self, c: Coordinate) -> bool {
        let curr_height = self.get_height(c);
        let neighbor_heights: Vec<u8> = self
            .neighbor_coords(c)
            .into_iter()
            .map(|c| self.get_height(c))
            .collect();

        curr_height < neighbor_heights.into_iter().min().unwrap()
    }

    fn neighbor_coords(&self, c: Coordinate) -> Vec<Coordinate> {
        let (x, y) = c;
        let ix = isize::try_from(x).unwrap();
        let iy = isize::try_from(y).unwrap();

        vec![(ix - 1, iy), (ix + 1, iy), (ix, iy - 1), (ix, iy + 1)]
            .into_iter()
            .filter(|c| self.in_bounds(c))
            .map(|(nx, ny)| (usize::try_from(nx).unwrap(), usize::try_from(ny).unwrap()))
            .collect()
    }

    fn in_bounds(&self, (x, y): &(isize, isize)) -> bool {
        x >= &0 && x < &self.inum_rows && y >= &0 && y < &self.inum_cols
    }

    fn get_height(&self, (x, y): Coordinate) -> u8 {
        self.grid[x][y]
    }
}

fn main() {
    let filename = "input/input.txt";
    let heightmap: Heightmap = Heightmap::new(parse_input_file(filename));

    println!("heightmap: {:?}", heightmap);
    println!();

    // Part 1
    let low_points = heightmap.find_low_points();
    println!("low points: {:?}", low_points);

    let risk_levels: Vec<usize> = low_points
        .iter()
        .map(|c| usize::from(heightmap.get_height(*c) + 1))
        .collect();

    println!("risk levels: {:?}", risk_levels);
    println!(
        "sum of risk levels: {:?}",
        risk_levels.iter().sum::<usize>()
    );

    // Part 2
    let basins: Vec<HashSet<Coordinate>> = heightmap.find_basins(&low_points);
    println!("basins: {:?}", basins);
    let mut basin_sizes: BinaryHeap<_> = basins.iter().map(|b| b.len()).collect();
    println!("basin sizes: {:?}", basin_sizes);

    let num_largest = 3;
    let largest_basin_sizes: Vec<_> = (0..num_largest)
        .into_iter()
        .map(|_| basin_sizes.pop().unwrap())
        .collect();

    println!(
        "{} largest basin sizes: {:?}",
        num_largest, largest_basin_sizes
    );
    println!(
        "product of {} largest basin sizes: {:?}",
        num_largest,
        largest_basin_sizes.into_iter().product::<usize>()
    )
}

fn parse_input_file(filename: &str) -> Vec<Vec<u8>> {
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

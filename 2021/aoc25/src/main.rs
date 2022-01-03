use std::fmt::{Display, Formatter};
use std::fs;

#[derive(Clone, Debug, PartialEq, Eq)]
enum Cucumber {
    East,
    South,
}

#[derive(Clone, Debug, PartialEq, Eq)]
struct SeaFloor {
    grid: Vec<Vec<Option<Cucumber>>>,
}

impl SeaFloor {
    fn new_empty(width: usize, height: usize) -> Self {
        SeaFloor {
            grid: vec![vec![None; height]; width],
        }
    }

    fn step(&mut self) -> bool {
        let width = self.grid.len();
        let height = self.grid[0].len();

        let mut changed = false;

        let mut moved_east = SeaFloor::new_empty(width, height);

        // move east
        for x in 0..width {
            for y in 0..height {
                if let Some(c) = &self.grid[x][y] {
                    moved_east.grid[x][y] = Some(c.clone());
                    if let Cucumber::East = c {
                        let next_y = (y + 1) % height;
                        if self.is_empty(x, next_y) {
                            changed = true;
                            moved_east.grid[x][next_y] = Some(Cucumber::East);
                            moved_east.grid[x][y] = None;
                        }
                    }
                }
            }
        }

        // move south
        let mut moved_south = SeaFloor::new_empty(width, height);

        for x in 0..width {
            for y in 0..height {
                if let Some(c) = &moved_east.grid[x][y] {
                    moved_south.grid[x][y] = Some(c.clone());
                    if let Cucumber::South = c {
                        let next_x = (x + 1) % width;
                        if moved_east.is_empty(next_x, y) {
                            changed = true;
                            moved_south.grid[next_x][y] = Some(Cucumber::South);
                            moved_south.grid[x][y] = None;
                        }
                    }
                }
            }
        }

        self.grid = moved_south.grid;
        changed
    }

    fn is_empty(&self, x: usize, y: usize) -> bool {
        self.grid[x][y].is_none()
    }
}

impl From<&str> for SeaFloor {
    fn from(seafloor_str: &str) -> Self {
        SeaFloor {
            grid: seafloor_str
                .split('\n')
                .map(|l| {
                    l.chars()
                        .map(|c| match c {
                            '.' => None,
                            '>' => Some(Cucumber::East),
                            'v' => Some(Cucumber::South),
                            x => panic!("could not parse character: {}", x),
                        })
                        .collect()
                })
                .collect(),
        }
    }
}

impl Display for SeaFloor {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        let grid_str: String = self
            .grid
            .iter()
            .map(|row| {
                row.iter()
                    .map(|c| match c {
                        None => '.',
                        Some(Cucumber::East) => '>',
                        Some(Cucumber::South) => 'v',
                    })
                    .collect::<String>()
            })
            .collect::<Vec<String>>()
            .join("\n");
        write!(f, "{}", grid_str)
    }
}

fn main() {
    let filename = "input/input.txt";
    let file_contents = fs::read_to_string(filename).unwrap();
    let mut sea_floor = SeaFloor::from(file_contents.as_str());

    println!("sea_floor:\n{}", sea_floor);
    println!();

    // keep advancing sea floor until it doesn't change
    let mut counter = 1;
    while sea_floor.step() {
        counter += 1;
    }
    println!("counter: {}", counter);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_line() {
        let mut seafloor = SeaFloor::from("...>>>>>...");
        seafloor.step();
        seafloor.step();
        assert_eq!(seafloor.to_string(), "...>>>.>.>.")
    }

    #[test]
    fn test_east_then_south() {
        let mut seafloor = SeaFloor::from(
            "..........
.>v....v..
.......>..
..........",
        );
        seafloor.step();

        assert_eq!(
            seafloor.to_string(),
            "..........
.>........
..v....v>.
.........."
        )
    }

    #[test]
    fn test_wrap() {
        let mut seafloor = SeaFloor::from(
            "...>...
.......
......>
v.....>
......>
.......
..vvv..",
        );
        seafloor.step();

        assert_eq!(
            seafloor.to_string(),
            "..vv>..
.......
>......
v.....>
>......
.......
....v.."
        );

        seafloor.step();
        seafloor.step();
        seafloor.step();
        assert_eq!(
            seafloor.to_string(),
            ">......
..v....
..>.v..
.>.v...
...>...
.......
v......"
        );
    }
}

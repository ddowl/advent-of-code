use std::collections::HashSet;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::ops::RangeInclusive;

#[derive(Debug, Hash, Eq, PartialEq)]
struct Point {
    x: usize,
    y: usize,
}

#[derive(Debug)]
struct LineSegment(Point, Point);

/**
Note to self: If I were to go back and do this again, I'd pursue the "intersection of line segments" strategy rather than "evaluate coverage over each point" strategy.
We know that it's the more efficient method, and the addition of the diagonal lines gave the former strategy a number of edge cases that were tricky to account for.
*/

fn main() {
    let filename = "input/input.txt";
    let line_segments: Vec<LineSegment> = parse_input_file(filename);

    println!("all line segments: {:?}", line_segments);
    println!();

    // Part 1
    // let hv_line_segments: Vec<LineSegment> = line_segments
    //     .into_iter()
    //     .filter(|ls| ls.is_horizontal() || ls.is_vertical())
    //     .collect();

    // println!(
    //     "horizontal and vertical line segments: {:?}",
    //     hv_line_segments
    // );
    // println!();

    // let num_covered_points = count_covered_points(&hv_line_segments);

    // Part 2
    let num_covered_points = count_covered_points(&line_segments);

    println!("num_covered_points: {}", num_covered_points);
    println!();
}

// Simpler to implement, but less efficient due to querying every discrete point.
fn count_covered_points(segments: &Vec<LineSegment>) -> usize {
    let max_x = segments
        .iter()
        .flat_map(|ls| vec![ls.0.x, ls.1.x])
        .max()
        .unwrap();
    let max_y = segments
        .iter()
        .flat_map(|ls| vec![ls.0.y, ls.1.y])
        .max()
        .unwrap();

    let mut num_covered_points = 0;
    for x in 0..=max_x {
        for y in 0..=max_y {
            let p = Point { x, y };
            // println!("checking point {:?}", p);
            let covering_segments: Vec<_> = segments.iter().filter(|&ls| ls.contains(&p)).collect();
            if covering_segments.len() > 1 {
                // println!("{:?} covers {:?}", covering_segments, p);
                num_covered_points += 1;
            }
        }
    }
    num_covered_points
}

// More efficient, but more complicated from line segment intersection logic.
fn count_intersecting_points(segments: &Vec<LineSegment>) -> usize {
    let mut intersecting_points: HashSet<Point> = HashSet::new();
    for i in 0..segments.len() {
        for j in (i + 1)..segments.len() {
            segments[i]
                .intersects(&segments[j])
                .into_iter()
                .for_each(|p| {
                    intersecting_points.insert(p);
                })
        }
    }
    // println!("{:?}", intersecting_points);
    intersecting_points.len()
}

fn parse_input_file(filename: &str) -> Vec<LineSegment> {
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).expect("couldn't open file");
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    reader
        .lines()
        .map(|line_res| line_res.expect("couldn't unwrap line"))
        .map(|line| {
            let line_seg_vec: Vec<Vec<usize>> = line
                .split(" -> ")
                .map(|l| l.split(",").map(|n| n.parse::<usize>().unwrap()).collect())
                .collect();
            assert_eq!(line_seg_vec.len(), 2);
            assert_eq!(line_seg_vec[0].len(), 2);
            assert_eq!(line_seg_vec[1].len(), 2);

            LineSegment(
                Point {
                    x: line_seg_vec[0][0],
                    y: line_seg_vec[0][1],
                },
                Point {
                    x: line_seg_vec[1][0],
                    y: line_seg_vec[1][1],
                },
            )
        })
        .collect()
}

impl LineSegment {
    fn is_horizontal(&self) -> bool {
        self.0.y == self.1.y
    }

    fn is_vertical(&self) -> bool {
        self.0.x == self.1.x
    }

    fn contains(&self, p: &Point) -> bool {
        let xrange = valid_range(self.0.x, self.1.x);
        let yrange = valid_range(self.0.y, self.1.y);
        let within_range = xrange.contains(&p.x) && yrange.contains(&p.y);

        if self.is_horizontal() || self.is_vertical() {
            within_range
        } else {
            // println!("diagonal slope! {:?}, {:?}", self, p,);
            // check if slope between p and self.0 is the same as self.0 and self.1

            if p == &self.0 || p == &self.1 {
                return true;
            }
            let self_slope = LineSegment::slope(&self.0, &self.1);
            let point_slope = LineSegment::slope(&self.0, p);

            if let (Some(self_slope), Some(point_slope)) = (self_slope, point_slope) {
                // println!("{:?}, {:?}", self_slope, point_slope);
                self_slope == point_slope && within_range
            } else {
                false
            }
        }
    }

    // Determines points of intersection between this line and another.
    // Note that now lines are _only_ horizontal or vertical.
    fn intersects(&self, other: &LineSegment) -> Vec<Point> {
        if self.is_horizontal() && other.is_horizontal() {
            if self.0.y == other.0.y {
                // potentially coinciding
                let xrange = self.0.x..=self.1.x;
                if xrange.contains(&other.0.x) || xrange.contains(&other.1.x) {
                    return (other.0.x..=other.1.x)
                        .filter(|x| xrange.contains(x))
                        .map(|x| Point { x, y: self.0.y })
                        .collect();
                }
            }
        } else if self.is_vertical() && other.is_vertical() {
            if self.0.x == other.0.x {
                // potentially coinciding
                let yrange = self.0.y..=self.1.y;
                if yrange.contains(&other.0.y) || yrange.contains(&other.1.y) {
                    return (other.0.y..=other.1.y)
                        .filter(|y| yrange.contains(y))
                        .map(|y| Point { x: self.0.x, y })
                        .collect();
                }
            }
        } else {
            // TODO
            return vec![];
        }
        vec![]
    }

    fn slope(a: &Point, b: &Point) -> Option<(isize, isize)> {
        let diff_y = isize::try_from(b.y).unwrap() - isize::try_from(a.y).unwrap();
        let diff_x = isize::try_from(b.x).unwrap() - isize::try_from(a.x).unwrap();
        // println!("{}, {}", diff_y, diff_x);

        let div = diff_y.checked_div(diff_x);
        let rem = diff_y.checked_rem(diff_x);
        if let (Some(div), Some(rem)) = (div, rem) {
            Some((div, rem))
        } else {
            None
        }
    }
}

fn valid_range(a: usize, b: usize) -> RangeInclusive<usize> {
    if a < b {
        a..=b
    } else {
        b..=a
    }
}

use std::cmp::{max, min};
use std::fs;
use std::ops::RangeInclusive;

type Cuboid = [RangeInclusive<isize>; 3];
type RebootInstruction = (bool, Cuboid);

fn main() {
    let filename = "input/input.txt";
    let instructions = parse_input_file(filename);

    println!("instructions: {:?}", instructions);
    println!();

    // Maintain two sets: positive regions and negative regions:
    // Accumulate intersections with positive regions, add intersections to negative regions
    // Accumulate intersections with negative regions, add intersections to positive regions
    // If a cuboid region is turning on, then
    //      - Add cuboid to positive region

    let mut positive_regions: Vec<Cuboid> = Vec::new();
    let mut negative_regions: Vec<Cuboid> = Vec::new();

    let sum_volumes = |regions: &Vec<Cuboid>| regions.iter().map(volume).sum();

    for (toggle, cuboid) in instructions {
        let agg_intersections = |regions: &Vec<Cuboid>| {
            regions
                .iter()
                .filter_map(|pr| intersection(&cuboid, pr))
                .collect()
        };

        let positive_intersections: Vec<Cuboid> = agg_intersections(&positive_regions);
        let negative_intersections: Vec<Cuboid> = agg_intersections(&negative_regions);

        negative_regions.extend(positive_intersections);
        positive_regions.extend(negative_intersections);

        if toggle {
            positive_regions.push(cuboid);
        }
    }

    let positive_volume: usize = sum_volumes(&positive_regions);
    let negative_volume: usize = sum_volumes(&negative_regions);
    println!("positive_volume: {:?}", positive_volume);
    println!("negative_volume: {:?}", negative_volume);
    println!("total_volume: {}", positive_volume - negative_volume);

    let init_cuboid: Cuboid = [-50..=50, -50..=50, -50..=50];
    let regions_in_init = |regions: &Vec<Cuboid>| {
        regions
            .iter()
            .filter_map(|r| intersection(r, &init_cuboid))
            .collect()
    };

    let positive_regions_in_init: Vec<Cuboid> = regions_in_init(&positive_regions);
    let negative_regions_in_init: Vec<Cuboid> = regions_in_init(&negative_regions);

    let positive_volume_in_init: usize = sum_volumes(&positive_regions_in_init);
    let negative_volume_in_init: usize = sum_volumes(&negative_regions_in_init);

    println!("positive_volume_in_init: {:?}", positive_volume_in_init);
    println!("negative_volume_in_init: {:?}", negative_volume_in_init);
    println!(
        "total_volume in init: {}",
        positive_volume_in_init - negative_volume_in_init
    );
}

// aka count_voxels
fn volume(cuboid: &Cuboid) -> usize {
    cuboid
        .iter()
        .map(|r| usize::try_from((r.end() - r.start() + 1).abs()).unwrap())
        .product()
}

// These would be great in an impl block, but impling over a type alias isn't possible, and alternatives (tuple struct & trait impl) are clunky
fn intersection(this: &Cuboid, that: &Cuboid) -> Option<Cuboid> {
    let x_start = max(this[0].start(), that[0].start());
    let x_end = min(this[0].end(), that[0].end());
    let y_start = max(this[1].start(), that[1].start());
    let y_end = min(this[1].end(), that[1].end());
    let z_start = max(this[2].start(), that[2].start());
    let z_end = min(this[2].end(), that[2].end());

    if x_start > x_end || y_start > y_end || z_start > z_end {
        None
    } else {
        Some([*x_start..=*x_end, *y_start..=*y_end, *z_start..=*z_end])
    }
}

fn parse_input_file(filename: &str) -> Vec<RebootInstruction> {
    let file_contents = fs::read_to_string(filename).unwrap();
    file_contents
        .split('\n')
        .map(|s| {
            let mut space_split = s.split_whitespace();
            let toggle: bool = space_split.next().unwrap() == "on";

            let get_range = |r: &str| {
                let mut range_iter = r[2..].split("..");
                let start: isize = range_iter.next().unwrap().parse().unwrap();
                let end: isize = range_iter.next().unwrap().parse().unwrap();
                start..=end
            };
            let mut axis_split = space_split.next().unwrap().split(',');
            let x_range = get_range(axis_split.next().unwrap());
            let y_range = get_range(axis_split.next().unwrap());
            let z_range = get_range(axis_split.next().unwrap());
            (toggle, [x_range, y_range, z_range])
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    fn cube(r: RangeInclusive<isize>) -> Cuboid {
        [r.clone(), r.clone(), r]
    }

    #[test]
    fn test_intersection() {
        let tests = HashMap::from([
            // non-overlapping
            ((cube(0..=2), cube(3..=6)), None),
            // overlap one voxel
            ((cube(0..=2), cube(2..=3)), Some(cube(2..=2))),
            // overlap edge
            (
                (cube(0..=3), [3..=6, 0..=3, 0..=3]),
                Some([3..=3, 0..=3, 0..=3]),
            ),
            // second greater
            ((cube(0..=3), cube(1..=4)), Some(cube(1..=3))),
            // first greater
            ((cube(1..=4), cube(0..=3)), Some(cube(1..=3))),
            // first encapsulated
            ((cube(0..=5), cube(1..=3)), Some(cube(1..=3))),
            // second encapsulated
            ((cube(1..=3), cube(0..=5)), Some(cube(1..=3))),
        ]);
        for ((a, b), expected_intersection) in tests {
            println!("{:?}", (&a, &b));
            let actual_intersection = intersection(&a, &b);
            assert_eq!(actual_intersection, expected_intersection);
        }
    }
}

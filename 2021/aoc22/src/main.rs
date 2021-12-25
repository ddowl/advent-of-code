use std::cmp::{max, min};
use std::collections::HashSet;
use std::fs;
use std::ops::RangeInclusive;

type Voxel = [isize; 3];
type Cuboid = [RangeInclusive<isize>; 3];
type RebootInstruction = (bool, Cuboid);

fn main() {
    let filename = "input/input.txt";
    let instructions = parse_input_file(filename);

    println!("instructions: {:?}", instructions);
    println!();

    let mut voxel_set: HashSet<Voxel> = HashSet::new();
    for (toggle, cuboid) in instructions {
        // println!("instructions: {:?}", (toggle, &cuboid));
        let restricted_cuboid = insersection_with_init_region(&cuboid);
        println!("restricted_cuboid: {:?}", restricted_cuboid);
        let voxels: Vec<_> = voxels_in(&restricted_cuboid);
        // println!("voxels: {:?}", voxels);

        voxels.into_iter().for_each(|v| {
            if toggle {
                voxel_set.insert(v);
            } else {
                voxel_set.remove(&v);
            }
        });
    }

    // println!("voxel_set: {:?}", voxel_set);
    println!("num voxels: {}", voxel_set.len());
}

fn in_init_region(voxel: &Voxel) -> bool {
    voxel.iter().all(|n| (-50..50).contains(n))
}

fn insersection_with_init_region(cuboid: &Cuboid) -> Cuboid {
    cuboid
        .clone()
        .map(|range| max(-50, *range.start())..=min(50, *range.end()))
}

fn voxels_in(cuboid: &Cuboid) -> Vec<Voxel> {
    let [x_range, y_range, z_range] = cuboid;
    x_range
        .clone()
        .flat_map(|x| {
            y_range
                .clone()
                .flat_map(move |y| z_range.clone().map(move |z| [x, y, z]))
        })
        .collect()
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

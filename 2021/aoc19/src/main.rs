use itertools::Itertools;
use std::collections::{HashMap, HashSet};
use std::fs;

type Position = [isize; 3];
type Vector = [isize; 3];

fn main() {
    let filename = "input/test.txt";
    let relative_beacon_positions_to_scanners = parse_input_file(filename);
    let num_scanners = relative_beacon_positions_to_scanners.len();

    // If we store the vectors (slope, magnitude) that describe the difference in space in a given scanner's set of Positions,
    // we should be able to intersect those vectors against some other scanner's positions in some orientation.
    // If we find at least 12 vectors in common, then we know that those vectors correspond to the _same_ position in space.
    // We should probably build up a set of "absolute" points as we go, i.e. all points relative to scanner 0.
    // "True" cardinality can be set by scanner 0's orientation, other scanner's beacon's vectors can be translated through different orientations until a match is found.

    // we only know the "correct" vector mappings of scanner 0 at the start, since that's our defined "absolute" orientation
    let scanner0_beacons = relative_beacon_positions_to_scanners.get(0).unwrap();
    let mut scanner_vectors_in_absolute_orientation: Vec<HashMap<Vector, [Position; 2]>> =
        vec![HashMap::new(); num_scanners];
    scanner_vectors_in_absolute_orientation[0] = vectors(scanner0_beacons);

    let mut all_beacon_positions: Vec<Vec<Vec<Position>>> = vec![];
    for relative_beacons in relative_beacon_positions_to_scanners.iter() {
        let scanner_beacon_positions: Vec<Vec<Position>> = transpose(
            relative_beacons
                .iter()
                .map(|p| all_orientations(p).collect())
                .collect(),
        );
        all_beacon_positions.push(scanner_beacon_positions);
    }

    let mut known_beacons: HashSet<Position> = HashSet::from_iter(scanner0_beacons.iter().cloned());
    let mut known_scanner_idxs: HashSet<usize> = HashSet::new();
    known_scanner_idxs.insert(0);
    let mut scanner_positions: Vec<Option<Position>> =
        Vec::from_iter(relative_beacon_positions_to_scanners.iter().map(|_| None));
    scanner_positions[0] = Some([0, 0, 0]);

    while scanner_positions.iter().any(|p| p.is_none()) {
        for unknown_scanner_idx in
            scanner_positions
                .clone()
                .iter()
                .enumerate()
                .filter_map(|(i, p)| match p {
                    None => Some(i),
                    Some(_) => None,
                })
        {
            find_intersecting_scanner(
                unknown_scanner_idx,
                &all_beacon_positions,
                &mut scanner_vectors_in_absolute_orientation,
                &mut scanner_positions,
                &mut known_beacons,
            );
        }
    }

    assert!(scanner_positions.iter().all(|p| p.is_some()));

    println!("scanner_positions: {:?}", scanner_positions);
    println!("known_beacons: {:?}", known_beacons);
    println!("num known_beacons: {:?}", known_beacons.len());

    let known_scanner_positions: Vec<Position> =
        scanner_positions.into_iter().map(|p| p.unwrap()).collect();

    let max_manhattan_dist: isize = known_scanner_positions
        .iter()
        .cartesian_product(known_scanner_positions.iter())
        .map(|(a, b)| diff(a, b).iter().sum())
        .max()
        .unwrap();

    println!("max_manhattan_dist: {}", max_manhattan_dist);
}

fn find_intersecting_scanner(
    target_scanner_idx: usize,
    all_beacon_positions: &Vec<Vec<Vec<Position>>>,
    scanner_vectors_in_absolute_orientation: &mut Vec<HashMap<Vector, [Position; 2]>>,
    scanner_positions: &mut Vec<Option<Position>>,
    known_beacons: &mut HashSet<Position>,
) {
    for target_beacons in all_beacon_positions.get(target_scanner_idx).unwrap() {
        let target_scanner_vector_mapping = vectors(target_beacons);
        let target_scanner_vectors: HashSet<&Vector> =
            target_scanner_vector_mapping.keys().collect();

        for (source_scanner_idx, source_scanner_pos) in scanner_positions
            .iter()
            .enumerate()
            .filter_map(|(i, pos)| pos.map(|p| (i, p)))
        {
            let source_scanner_vector_mapping = scanner_vectors_in_absolute_orientation
                .get(source_scanner_idx)
                .unwrap();

            let source_scanner_vectors: HashSet<&Vector> =
                source_scanner_vector_mapping.keys().collect();

            let vector_intersection: HashSet<&Vector> = source_scanner_vectors
                .intersection(&target_scanner_vectors)
                .cloned()
                .collect();

            let matching_positions: HashSet<Position> = vector_intersection
                .clone()
                .into_iter()
                .flat_map(|v| source_scanner_vector_mapping[v])
                .collect();

            // overlaps if more than 12 matching positions
            if matching_positions.len() >= 12 {
                // one vector should yield positions in both scanners, diff between positions is the diff between scanners
                let v = vector_intersection.into_iter().next().unwrap();
                let beacon_source = source_scanner_vector_mapping[v][0];
                let beacon_target = target_scanner_vector_mapping[v][0];
                let scanner_diff = diff(&beacon_source, &beacon_target);
                let target_scanner_pos = translate(&source_scanner_pos, &scanner_diff);

                // Set "absolute" scanner position
                scanner_positions[target_scanner_idx] = Some(target_scanner_pos);

                // Save vectors between beacons of scanner in "absolute" orientation
                scanner_vectors_in_absolute_orientation[target_scanner_idx] =
                    target_scanner_vector_mapping;

                // TODO: translate from current pos using source scanner pos as diff vector
                let target_beacons_relative_to_scanner_0: Vec<Position> = target_beacons
                    .iter()
                    .map(|p| translate(p, &target_scanner_pos))
                    .collect();

                // TODO: translate in terms of scanner 0
                // add beacons in "absolute" orientation translated to scanner 0 reference to known set
                for tb in target_beacons_relative_to_scanner_0 {
                    known_beacons.insert(tb);
                }
                return;
            }
        }
    }
}

// can improve performance by returning position references as values, cloning at last second
fn vectors(beacons: &[Position]) -> HashMap<Vector, [Position; 2]> {
    beacons
        .iter()
        .cartesian_product(beacons.iter())
        .filter(|(a, b)| a != b)
        .map(|(a, b)| (diff(a, b), [*a, *b]))
        .collect()
}

fn transpose<T>(v: Vec<Vec<T>>) -> Vec<Vec<T>> {
    assert!(!v.is_empty());
    let len = v[0].len();
    let mut iters: Vec<_> = v.into_iter().map(|n| n.into_iter()).collect();
    (0..len)
        .map(|_| {
            iters
                .iter_mut()
                .map(|n| n.next().unwrap())
                .collect::<Vec<T>>()
        })
        .collect()
}

type PositionTransformation = ((isize, isize, isize), (usize, usize, usize));

const orientation_transformations: [PositionTransformation; 6] = [
    ((1, 1, 1), (0, 1, 2)),
    ((-1, -1, 1), (0, 1, 2)),
    ((1, -1, 1), (1, 0, 2)),
    ((-1, 1, 1), (1, 0, 2)),
    ((1, 1, -1), (2, 1, 0)),
    ((-1, 1, 1), (2, 1, 0)),
];

// yields transformations: (x, y, z), (x, z, -y), (x, -y, -z), (x, -z, y)
const rotation_transformations: [PositionTransformation; 4] = [
    ((1, 1, 1), (0, 1, 2)),
    ((1, 1, -1), (0, 2, 1)),
    ((1, -1, -1), (0, 1, 2)),
    ((1, -1, 1), (0, 2, 1)),
];

fn all_orientations(p: &Position) -> impl Iterator<Item = Position> {
    orientations(*p).flat_map(rotations)
}

// Face scanner observing beacon (1, 2, 3) in different cardinal directions
// xpos: (1, 2, 3)
// xneg: (-1, -2, 3)
// ypos: (2, -1, 3)
// yneg: (-2, 1, 3)
// zpos: (3, 2, -1)
// zneg: (-3, 2, 1)
// yields transformations (x, y, z), (-x, -y, z), (y, -x, z), (-y, x, z), (z, y, -x), (-z, y, x)
fn orientations(p: Position) -> impl Iterator<Item = Position> {
    orientation_transformations.into_iter().map(
        move |((x_sign, y_sign, z_sign), (x_idx, y_idx, z_idx))| {
            [x_sign * p[x_idx], y_sign * p[y_idx], z_sign * p[z_idx]]
        },
    )
}

// Rotate scanner observing beacon (1, 2, 3) around x axis
// x value is fixed
// (1, 2, 3)
// (1, 3, -2)
// (1, -2, -3)
// (1, -3, 2)
// yields transformations: (x, y, z), (x, z, -y), (x, -y, -z), (x, -z, y)
fn rotations(p: Position) -> impl Iterator<Item = Position> {
    rotation_transformations.into_iter().map(
        move |((x_sign, y_sign, z_sign), (x_idx, y_idx, z_idx))| {
            [x_sign * p[x_idx], y_sign * p[y_idx], z_sign * p[z_idx]]
        },
    )
}

fn diff(a: &Position, b: &Position) -> Vector {
    [a[0] - b[0], a[1] - b[1], a[2] - b[2]]
}

fn translate(p: &Position, v: &Vector) -> Position {
    [p[0] + v[0], p[1] + v[1], p[2] + v[2]]
}

fn parse_input_file(filename: &str) -> Vec<Vec<Position>> {
    let file_contents = fs::read_to_string(filename).unwrap();
    file_contents
        .split("\n\n")
        .map(parse_scanner_beacons)
        .collect()
}

fn parse_scanner_beacons(beacons_str: &str) -> Vec<Position> {
    beacons_str
        .split('\n')
        .skip(1)
        .map(|pos_str| {
            println!("{}", pos_str);
            let positions: Vec<isize> = pos_str.split(',').map(|n| n.parse().unwrap()).collect();
            assert_eq!(positions.len(), 3);
            [positions[0], positions[1], positions[2]]
        })
        .collect()
}

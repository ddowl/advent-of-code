use std::collections::HashSet;
use std::fs;

type Coordinate = (usize, usize);

#[derive(Debug, Clone, Copy)]
enum Axis {
    Vertical,
    Horizontal,
}

type FoldInstruction = (Axis, usize);

fn main() {
    let filename = "input/input.txt";
    let (coords, fold_instructions) = parse_input_file(filename);

    println!("coords: {:?}", coords);
    println!("fold_instructions: {:?}", fold_instructions);
    println!();

    let mut coord_set: HashSet<Coordinate> = HashSet::from_iter(coords);

    apply_fold(fold_instructions[0], &mut coord_set);
    println!("coord_set size: {:?}", coord_set.len());
}

fn apply_fold(f: FoldInstruction, coord_set: &mut HashSet<Coordinate>) {
    let (fold_axis, fold_value) = f;
    let affected_coords: Vec<_> = coord_set
        .iter()
        .filter(|(x, y)| {
            let coord_value = match fold_axis {
                Axis::Vertical => x,
                Axis::Horizontal => y,
            };
            coord_value > &fold_value
        })
        .cloned()
        .collect();

    for c in affected_coords {
        flip_across_fold(coord_set, c, f);
    }
}

fn flip_across_fold(
    coord_set: &mut HashSet<Coordinate>,
    coord: Coordinate,
    fold_instruction: FoldInstruction,
) {
    let (x, y) = coord;
    let (fold_axis, fold_value) = fold_instruction;

    let distance_from_fold_line = match fold_axis {
        Axis::Horizontal => y - fold_value,
        Axis::Vertical => x - fold_value,
    };

    let across_fold_line = fold_value - distance_from_fold_line;

    let folded_coord = match fold_axis {
        Axis::Horizontal => (x, across_fold_line),
        Axis::Vertical => (across_fold_line, y),
    };

    coord_set.remove(&coord);
    coord_set.insert(folded_coord);
}

fn parse_input_file(filename: &str) -> (Vec<Coordinate>, Vec<FoldInstruction>) {
    let file_contents = fs::read_to_string(filename).unwrap();
    let mut newline_splitter = file_contents.split("\n\n");
    let (coord_str, instr_str) = (
        newline_splitter.next().unwrap(),
        newline_splitter.next().unwrap(),
    );

    let coords: Vec<Coordinate> = coord_str
        .lines()
        .map(|l| {
            let ns: Vec<usize> = l.split(",").map(|n| n.parse().unwrap()).collect();
            assert_eq!(ns.len(), 2);
            (ns[0], ns[1])
        })
        .collect();

    let instr_prefix = "fold along ";
    let fold_instructions: Vec<FoldInstruction> = instr_str
        .lines()
        .map(|l| {
            let instr_parts: Vec<&str> = l.strip_prefix(instr_prefix).unwrap().split("=").collect();
            assert_eq!(instr_parts.len(), 2);
            let axis = match instr_parts[0] {
                "x" => Axis::Vertical,
                "y" => Axis::Horizontal,
                other => panic!("invalid axis type: {}", other),
            };
            let value: usize = instr_parts[1].parse().unwrap();
            (axis, value)
        })
        .collect();

    (coords, fold_instructions)
}

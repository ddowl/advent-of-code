use std::fs;

type Coordinate = (usize, usize);

#[derive(Debug)]
enum Axis {
    Vertical,
    Horizontal,
}
type FoldInstruction = (Axis, usize);

fn main() {
    let filename = "input/test.txt";
    let (coords, fold_instructions) = parse_input_file(filename);

    println!("coords: {:?}", coords);
    println!("fold_instructions: {:?}", fold_instructions);
    println!();
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
                "x" => Axis::Horizontal,
                "y" => Axis::Vertical,
                other => panic!("invalid axis type: {}", other),
            };
            let value: usize = instr_parts[1].parse().unwrap();
            (axis, value)
        })
        .collect();

    (coords, fold_instructions)
}

use std::collections::HashMap;
use std::fs::File;
use std::io::{BufRead, BufReader};

type BingoIndex = HashMap<usize, (usize, usize)>;
type BingoBoard = [[(usize, bool); 5]; 5];

fn main() {
    let filename = "input/input.txt";
    let (drawn_numbers, boards) = parse_input_file(filename);

    println!("drawn_numbers: {:?}", drawn_numbers);
    // println!("boards: {:?}", boards);
    boards.iter().for_each(|(bidx, board)| {
        println!("{:?}", bidx);
        print_board(board)
    });

    let (final_drawn_number, winning_board) = match play_bingo(drawn_numbers, boards) {
        None => {
            panic!("no winning board found");
        }
        Some(x) => x,
    };

    println!("final drawn number: {}", final_drawn_number);
    print_board(&winning_board);

    let sum_of_unmarked_on_winning_board = sum_of_unmarked(&winning_board);
    println!(
        "sum_of_unmarked_on_winning_board: {}",
        sum_of_unmarked_on_winning_board
    );

    let score = final_drawn_number * sum_of_unmarked_on_winning_board;
    println!("score: {}", score);
}

fn play_bingo(
    drawn_numbers: Vec<usize>,
    mut boards: Vec<(BingoIndex, BingoBoard)>,
) -> Option<(usize, BingoBoard)> {
    for n in drawn_numbers {
        boards
            .iter_mut()
            .for_each(|(bidx, board)| mark_board(bidx, board, n));

        let maybe_winning_board = boards.iter().find(|&(_, board)| has_bingo(board));

        if let Some(&(_, winning_board)) = maybe_winning_board {
            return Some((n, winning_board));
        }
    }

    boards.iter().for_each(|&(_, b)| print_board(&b));
    None
}

fn mark_board(bidx: &BingoIndex, board: &mut BingoBoard, n: usize) {
    if let Some(&(x, y)) = bidx.get(&n) {
        board[x][y].1 = true;
    }
}

fn has_bingo(board: &BingoBoard) -> bool {
    // check all rows
    for i in 0..5 {
        let row = board[i];
        if row.iter().all(|&(_, marked)| marked) {
            return true;
        }
    }

    // check all columns
    for j in 0..5 {
        let mut col: [bool; 5] = [false; 5];
        for i in 0..5 {
            col[i] = board[i][j].1;
        }
        if col.iter().all(|&marked| marked) {
            return true;
        }
    }
    false
}

fn sum_of_unmarked(board: &BingoBoard) -> usize {
    board
        .iter()
        .map(|row| {
            row.iter()
                .filter(|&(_, marked)| *marked == false)
                .map(|&(n, _)| n)
                .sum::<usize>()
        })
        .sum()
}

fn parse_input_file(filename: &str) -> (Vec<usize>, Vec<(BingoIndex, BingoBoard)>) {
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).expect("couldn't open file");
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    let lines: Vec<String> = reader
        .lines()
        .map(|line_res| line_res.expect("couldn't unwrap line"))
        .collect();

    let drawn_numbers: Vec<usize> = lines
        .first()
        .expect("no lines read")
        .split(',')
        .map(|n| n.parse().unwrap())
        .collect();

    let boards: Vec<_> = lines
        .into_iter()
        .skip(1)
        .filter(|l| l != "")
        .map(|bl| bl.split_whitespace().map(|n| n.parse().unwrap()).collect())
        .collect::<Vec<Vec<usize>>>()
        .chunks(5)
        .map(|bls| {
            let mut board: BingoBoard = [[(0, false); 5]; 5];
            let mut bidx: BingoIndex = HashMap::new();
            for i in 0..5 {
                for j in 0..5 {
                    let &n = bls[i].get(j).unwrap();
                    if bidx.contains_key(&n) {
                        panic!("BingoMap already contains number: {}", n);
                    }
                    bidx.insert(n, (i, j));
                    board[i][j].0 = n
                }
            }
            (bidx, board)
        })
        .collect();

    (drawn_numbers, boards)
}

fn print_board(board: &BingoBoard) {
    board.iter().for_each(|l| println!("{:?}", l));
    println!();
}

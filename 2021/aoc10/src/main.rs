use phf::phf_map;
use std::fs::File;
use std::io::{BufRead, BufReader};

static CHUNK_SYMBOL_COMPLEMENTS: phf::Map<char, char> = phf_map! {
    '(' => ')',
    '[' => ']',
    '{' => '}',
    '<' => '>',
};

static SYNTAX_ERROR_SCORES: phf::Map<char, usize> = phf_map! {
    ')' => 3,
    ']' => 57,
    '}' => 1197,
    '>' => 25137,
};

#[derive(Debug, PartialEq, Eq)]
enum ChunkParseResult {
    Complete,
    Incomplete,
    Corrupted(char),
}

fn main() {
    let filename = "input/input.txt";
    let lines: Vec<String> = parse_input_file(filename);

    println!("lines: {:?}", lines);
    println!();

    let syntax_error_score: usize = lines
        .iter()
        .map(parse_chunks)
        .map(|e| match e {
            ChunkParseResult::Corrupted(c) => SYNTAX_ERROR_SCORES[&c],
            _ => 0,
        })
        .sum();
    println!("syntax_error_score: {}", syntax_error_score)
}

fn parse_chunks(syntax_line: &String) -> ChunkParseResult {
    let mut open_chunk_stack: Vec<char> = vec![];
    for c in syntax_line.chars() {
        if CHUNK_SYMBOL_COMPLEMENTS.contains_key(&c) {
            // opening chunk symbol
            // Add to stack and move to next char
            open_chunk_stack.push(c);
        } else {
            // closing chunk symbol
            // Peek stack to verify symbols are complements
            // If so, pop opening chunk symbol off stack, otherwise return Corrupted result
            match open_chunk_stack.last() {
                // Not sure about this one. This is like if we have an extra closing tag with no associated opening tag
                None => {
                    return ChunkParseResult::Corrupted(c);
                }
                Some(&opening) => {
                    if CHUNK_SYMBOL_COMPLEMENTS[&opening] == c {
                        open_chunk_stack.pop();
                    } else {
                        return ChunkParseResult::Corrupted(c);
                    }
                }
            }
        }
    }

    if open_chunk_stack.is_empty() {
        ChunkParseResult::Complete
    } else {
        ChunkParseResult::Incomplete
    }
}

fn parse_input_file(filename: &str) -> Vec<String> {
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).expect("couldn't open file");
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    reader.lines().map(|l| l.unwrap()).collect()
}

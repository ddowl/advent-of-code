use std::fs::File;
use std::io::{BufRead, BufReader};

fn main() {
    let filename = "input/input.txt";
    let binary_numbers = parse_input_file(filename);

    println!("{:?}", binary_numbers);

    let gamma_str = calculate_gamma_rate_str(&binary_numbers);
    let gamma_val = binary_str_to_num(&gamma_str);
    println!("gamma rate string: {}", gamma_str);
    println!("gamma rate value: {}", gamma_val);

    let epsilon_str = binary_complement(&gamma_str);
    let epsilon_val = binary_str_to_num(&epsilon_str);
    println!("epsilon rate: {}", epsilon_str);
    println!("epsilon rate: {}", epsilon_val);

    println!("gamma * epsilon: {}", gamma_val * epsilon_val)
}

fn parse_input_file(filename: &str) -> Vec<String> {
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).expect("couldn't open file");
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    reader
        .lines()
        .map(|line_res| line_res.expect("couldn't unwrap line"))
        .collect()
}

fn calculate_gamma_rate_str(binary_numbers: &Vec<String>) -> String {
    let binary_nums_as_chars: Vec<Vec<char>> =
        binary_numbers.iter().map(|n| n.chars().collect()).collect();

    (0..binary_numbers[0].len())
        .map(|i| {
            let (num_zeros, num_ones) = binary_nums_as_chars.iter().map(move |bn| bn[i]).fold(
                (0, 0),
                |(num_zeros, num_ones), n| {
                    if n == '0' {
                        (num_zeros + 1, num_ones)
                    } else {
                        (num_zeros, num_ones + 1)
                    }
                },
            );

            if num_zeros > num_ones {
                '0'
            } else {
                '1'
            }
        })
        .collect::<String>()
}

fn binary_complement(binary_str: &str) -> String {
    String::from(binary_str)
        .chars()
        .map(|d| if d == '0' { '1' } else { '0' })
        .collect()
}

fn binary_str_to_num(binary_str: &str) -> isize {
    isize::from_str_radix(binary_str, 2).unwrap()
}

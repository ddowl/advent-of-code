use std::fs::File;
use std::io::{BufRead, BufReader};

fn main() {
    let filename = "input/input.txt";
    let binary_numbers = parse_input_file(filename);

    // println!("{:?}", binary_numbers);

    // Part 1
    let gamma_str = calculate_gamma_rate_str(&binary_numbers);
    let gamma_val = binary_str_to_num(&gamma_str);
    println!("gamma rate string: {}", gamma_str);
    println!("gamma rate value: {}", gamma_val);

    let epsilon_str = binary_complement(&gamma_str);
    let epsilon_val = binary_str_to_num(&epsilon_str);
    println!("epsilon rate: {}", epsilon_str);
    println!("epsilon rate: {}", epsilon_val);

    println!("gamma * epsilon: {}", gamma_val * epsilon_val);

    // Part 2
    let oxygen_generator_rating = calculate_oxygen_generator_rating(&binary_numbers);
    println!("oxygen_generator_rating: {}", oxygen_generator_rating);

    let co2_scrubber_rating = calculate_co2_scrubber_rating(&binary_numbers);
    println!("co2_scrubber_rating: {}", co2_scrubber_rating);

    println!(
        "oxygen * co2: {}",
        oxygen_generator_rating * co2_scrubber_rating
    );
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
            let (num_zeros, num_ones) = count_digits(&binary_nums_as_chars, i);
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

fn calculate_oxygen_generator_rating(binary_numbers: &Vec<String>) -> isize {
    let mut binary_nums_as_chars: Vec<Vec<char>> =
        binary_numbers.iter().map(|n| n.chars().collect()).collect();

    let mut bit_position = 0;
    while binary_nums_as_chars.len() != 1 {
        let common_bit = most_common_bit(&binary_nums_as_chars, bit_position);

        // filter binary_numbers by only those that have the most common bit in this position
        let filtered_nums: Vec<Vec<char>> = binary_nums_as_chars
            .into_iter()
            .filter(|bn| bn[bit_position] == common_bit)
            .collect();

        binary_nums_as_chars = filtered_nums;
        bit_position += 1;
    }

    let oxygen_rating_str: String = binary_nums_as_chars
        .first()
        .expect("expected to find last binary number")
        .iter()
        .collect();

    println!("oxygen_rating_str: {}", oxygen_rating_str);
    binary_str_to_num(&oxygen_rating_str)
}

fn calculate_co2_scrubber_rating(binary_numbers: &Vec<String>) -> isize {
    let mut binary_nums_as_chars: Vec<Vec<char>> =
        binary_numbers.iter().map(|n| n.chars().collect()).collect();

    let mut bit_position = 0;
    while binary_nums_as_chars.len() != 1 {
        let common_bit = least_common_bit(&binary_nums_as_chars, bit_position);

        // filter binary_numbers by only those that have the most common bit in this position
        let filtered_nums: Vec<Vec<char>> = binary_nums_as_chars
            .into_iter()
            .filter(|bn| bn[bit_position] == common_bit)
            .collect();

        binary_nums_as_chars = filtered_nums;
        bit_position += 1;
    }

    let co2_scrubber_rating_str: String = binary_nums_as_chars
        .first()
        .expect("expected to find last binary number")
        .iter()
        .collect();

    println!("oxygen_rating_str: {}", co2_scrubber_rating_str);
    binary_str_to_num(&co2_scrubber_rating_str)
}

fn most_common_bit(binary_nums_as_chars: &Vec<Vec<char>>, i: usize) -> char {
    let (num_zeros, num_ones) = count_digits(binary_nums_as_chars, i);
    if num_zeros > num_ones {
        '0'
    } else {
        '1'
    }
}

fn least_common_bit(binary_nums_as_chars: &Vec<Vec<char>>, i: usize) -> char {
    let most_common_bit = most_common_bit(binary_nums_as_chars, i);
    if most_common_bit == '0' {
        '1'
    } else {
        '0'
    }
}

fn count_digits(binary_nums_as_chars: &Vec<Vec<char>>, i: usize) -> (usize, usize) {
    binary_nums_as_chars
        .iter()
        .map(move |bn| bn[i])
        .fold((0, 0), |(num_zeros, num_ones), n| {
            if n == '0' {
                (num_zeros + 1, num_ones)
            } else {
                (num_zeros, num_ones + 1)
            }
        })
}

use std::collections::{BTreeSet, HashMap};
use std::fs::File;
use std::io::{BufRead, BufReader};

type UniqueDigitCombinations = [String; 10];
type EncodedNumber = [String; 4];
type Display = (UniqueDigitCombinations, EncodedNumber);

fn main() {
    let filename = "input/input.txt";
    let displays: Vec<Display> = parse_input_file(filename);

    println!("displays: {:?}", displays);
    println!();

    // Part 1
    let unique_segment_counts = vec![2, 3, 4, 7];
    let num_digits_with_unique_segment_count = displays
        .iter()
        .map(|(_, digits)| {
            digits
                .iter()
                .filter(|&d| unique_segment_counts.contains(&d.len()))
        })
        .flatten()
        .count();

    println!(
        "num_digits_with_unique_segment_count: {}",
        num_digits_with_unique_segment_count
    );
    println!();

    let decoded_display_sum: usize = displays.iter().map(decode_display).sum();
    println!("decoded_display_sum: {}", decoded_display_sum);
}

fn decode_display(display: &Display) -> usize {
    let (digit_combos, encoded_digits) = display;

    let digit_decoder_map = deduce_wire_combinations(digit_combos);
    // println!("digit_decoder_map: {:?}", digit_decoder_map);

    let decoded_digits: Vec<usize> = encoded_digits
        .iter()
        .map(|combo| BTreeSet::from_iter(combo.chars()))
        .map(|combo| digit_decoder_map[&combo])
        .collect();

    // println!("{:?}", decoded_digits);

    let mut decoded_display = 0;
    for i in (0..4).rev() {
        // println!(
        //     "{}, {}, {}",
        //     i,
        //     decoded_digits[i],
        //     10_usize.pow((3 - i) as u32)
        // );
        decoded_display += 10_usize.pow((3 - i) as u32) * decoded_digits[i];
    }
    decoded_display
}

fn deduce_wire_combinations(
    digit_combos: &UniqueDigitCombinations,
) -> HashMap<BTreeSet<char>, usize> {
    let digit_combos: Vec<BTreeSet<char>> = digit_combos
        .iter()
        .map(|combo| BTreeSet::from_iter(combo.chars()))
        .collect();

    // println!("{:?}", digit_combos);

    // Can deduce by unique segment count
    let one: BTreeSet<char> = digit_combos
        .iter()
        .find(|combo| combo.len() == 2)
        .unwrap()
        .clone();
    let four: BTreeSet<char> = digit_combos
        .iter()
        .find(|combo| combo.len() == 4)
        .unwrap()
        .clone();
    let seven: BTreeSet<char> = digit_combos
        .iter()
        .find(|combo| combo.len() == 3)
        .unwrap()
        .clone();
    let eight: BTreeSet<char> = digit_combos
        .iter()
        .find(|combo| combo.len() == 7)
        .unwrap()
        .clone();
    // println!("{:?}, {:?}, {:?}, {:?}", one, four, seven, eight);

    let top_segment: char = seven.difference(&one).nth(0).copied().unwrap();
    // println!("top_segment: {}", top_segment);

    // Deduce middle segments from intersection of all 5 segment combos
    let five_segment_combos: Vec<&BTreeSet<char>> = digit_combos
        .iter()
        .filter(|combo| combo.len() == 5)
        .collect();
    // println!("five_segment_combos: {:?}", five_segment_combos);

    let mut top_middle_bottom_segments: BTreeSet<char> = BTreeSet::new();
    top_middle_bottom_segments = top_middle_bottom_segments.union(&eight).copied().collect();
    five_segment_combos.iter().for_each(|combo| {
        top_middle_bottom_segments = top_middle_bottom_segments
            .intersection(combo)
            .copied()
            .collect();
    });
    // println!("top_middle_bottom_rows: {:?}", top_middle_bottom_segments);

    let middle_bottom_segments: BTreeSet<char> = top_middle_bottom_segments
        .difference(&seven)
        .copied()
        .collect();
    // println!("middle_bottom_segments: {:?}", middle_bottom_segments);

    let middle_segment: char = middle_bottom_segments
        .intersection(&four)
        .copied()
        .nth(0)
        .unwrap();
    // println!("middle_segment: {:?}", middle_segment);

    let bottom_segment: char = middle_bottom_segments
        .difference(&BTreeSet::from([middle_segment]))
        .copied()
        .nth(0)
        .unwrap();
    // println!("bottom_segment: {:?}", bottom_segment);

    // add middle and bottom segments to 7 to get 3
    let three: BTreeSet<char> = seven.union(&middle_bottom_segments).copied().collect();
    // println!("three: {:?}", three);

    let top_left_segment: char = four
        .difference(
            &one.union(&BTreeSet::from([middle_segment]))
                .copied()
                .collect(),
        )
        .copied()
        .nth(0)
        .unwrap();
    // println!("top_left_segment: {:?}", top_left_segment);

    let two_and_five: Vec<&BTreeSet<char>> = five_segment_combos
        .into_iter()
        .filter(|&combo| combo != &three)
        .collect();
    // println!("two_and_five: {:?}", two_and_five);

    let five: BTreeSet<char> = two_and_five
        .iter()
        .find(|&&combo| combo.contains(&top_left_segment))
        .unwrap()
        .clone()
        .clone();
    // println!("five: {:?}", five);

    let two: BTreeSet<char> = two_and_five
        .into_iter()
        .find(|&combo| combo != &five)
        .unwrap()
        .clone();
    // println!("two: {:?}", two);

    let zero: BTreeSet<char> = eight
        .difference(&BTreeSet::from([middle_segment]))
        .copied()
        .collect();
    // println!("zero: {:?}", zero);

    let nine: BTreeSet<char> = four
        .union(&BTreeSet::from([top_segment, bottom_segment]))
        .copied()
        .collect();
    // println!("nine: {:?}", nine);

    let bottom_left_segment: char = eight.difference(&nine).copied().nth(0).unwrap();
    // println!("bottom_left_segment: {:?}", bottom_left_segment);

    let six: BTreeSet<char> = five
        .union(&BTreeSet::from([bottom_left_segment]))
        .copied()
        .collect();
    // println!("six: {:?}", six);

    HashMap::from_iter(
        vec![zero, one, two, three, four, five, six, seven, eight, nine]
            .into_iter()
            .zip(0..=9),
    )
}

fn parse_input_file(filename: &str) -> Vec<Display> {
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).expect("couldn't open file");
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    reader
        .lines()
        .map(|l| {
            let line = l.unwrap();
            let parts: Vec<&str> = line.split(" | ").collect();
            assert_eq!(parts.len(), 2);
            let digit_combinations: [String; 10] = into_array(parts[0]);
            let four_digit_display: [String; 4] = into_array(parts[1]);
            (digit_combinations, four_digit_display)
        })
        .collect()
}

fn into_array<const N: usize>(s: &str) -> [String; N] {
    s.split_whitespace()
        .map(<str>::to_string)
        .collect::<Vec<String>>()
        .try_into()
        .unwrap()
}

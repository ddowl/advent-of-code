use itertools::Itertools;
use std::collections::HashMap;
use std::fs;

fn main() {
    let filename = "input/input.txt";
    let (polymer, pair_insertion_rules) = parse_input_file(filename);

    println!("polymer_template: {:?}", polymer);
    println!("pair_insertion_rules: {:?}", pair_insertion_rules);
    println!();

    let mut element_pairs = to_element_pairs(&polymer);
    println!("element_pairs: {:?}", element_pairs);

    let mut pair_transformations: HashMap<String, Vec<String>> = HashMap::new();
    for (pair, inserted_char) in pair_insertion_rules.iter() {
        pair_transformations.insert(
            pair.clone(),
            vec![
                String::from_iter([pair.get(0..1).unwrap(), inserted_char]),
                String::from_iter([inserted_char, pair.get(1..).unwrap()]),
            ],
        );
    }
    println!("pair_transformations: {:?}", pair_transformations);

    let num_steps = 40;
    for i in 0..num_steps {
        println!("computing step {}...", i);
        element_pairs = polymerize_pairs(&element_pairs, &pair_transformations);
    }

    println!("resulting element_pairs: {:?}", element_pairs);
    let element_counts = char_counts(&element_pairs, &polymer);
    println!("polymer stats: {:?}", element_counts);

    let most_common = element_counts.values().max().unwrap();
    let least_common = element_counts.values().min().unwrap();
    println!("most_common - least_common: {}", most_common - least_common);
}

fn polymerize_pairs(
    element_pairs: &HashMap<String, usize>,
    pair_transformations: &HashMap<String, Vec<String>>,
) -> HashMap<String, usize> {
    let mut next_element_pairs: HashMap<String, usize> = HashMap::new();
    for (pair, num_pairs) in element_pairs {
        for new_pair in pair_transformations.get(pair).unwrap() {
            next_element_pairs
                .entry(String::from(new_pair))
                .and_modify(|n| *n += num_pairs)
                .or_insert(*num_pairs);
        }
    }

    next_element_pairs.retain(|_, num_pairs| num_pairs != &0);
    next_element_pairs
}

fn to_element_pairs(polymer_template: &str) -> HashMap<String, usize> {
    let mut element_pairs = HashMap::new();
    for i in 0..(polymer_template.len() - 1) {
        let pair = &polymer_template[i..=(i + 1)];
        let num_pairs = element_pairs.entry(pair.to_string()).or_insert(0);
        *num_pairs += 1;
    }
    return element_pairs;
}

fn char_counts(
    pairs: &HashMap<String, usize>,
    original_polymer_template: &str,
) -> HashMap<char, usize> {
    let mut counts: HashMap<char, usize> = HashMap::new();
    for (pair, num_pairs) in pairs {
        for c in pair.chars() {
            *counts.entry(c).or_insert(0) += num_pairs;
        }
    }

    let all_chars: Vec<char> = pairs.keys().flat_map(|p| p.chars()).unique().collect();
    let first_char = original_polymer_template.chars().nth(0).unwrap();
    let last_char = original_polymer_template
        .chars()
        .nth(original_polymer_template.len() - 1)
        .unwrap();

    // We double count all chars _except_ for the first and last char of the original polymer
    for c in all_chars {
        let num_cs = counts.entry(c).or_insert(0);
        *num_cs = if c == first_char || c == last_char {
            *num_cs / 2 + 1
        } else {
            *num_cs / 2
        };
    }

    counts
}

fn parse_input_file(filename: &str) -> (String, HashMap<String, String>) {
    let file_contents = fs::read_to_string(filename).unwrap();
    let (polymer_template, pair_insertion_rules_str) = file_contents
        .split("\n\n")
        .map(|s| s.to_string())
        .next_tuple()
        .unwrap();

    let pair_insertion_rules = HashMap::from_iter(
        pair_insertion_rules_str
            .split("\n")
            .map(|l| l.split(" -> ").map(|s| s.to_string()).next_tuple().unwrap()),
    );
    (polymer_template, pair_insertion_rules)
}

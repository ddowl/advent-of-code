use itertools::Itertools;
use std::collections::HashMap;
use std::fs;

fn main() {
    let filename = "input/input.txt";
    let (mut polymer, pair_insertion_rules) = parse_input_file(filename);

    println!("polymer_template: {:?}", polymer);
    println!("pair_insertion_rules: {:?}", pair_insertion_rules);
    println!();

    let num_steps = 10;
    for _ in 0..num_steps {
        polymer = polymerize(polymer, &pair_insertion_rules);
    }
    // println!("resulting polymer: {}", polymer);
    let element_counts = char_counts(&polymer);
    println!("polymer stats: {:?}", element_counts);

    let most_common = element_counts.values().max().unwrap();
    let least_common = element_counts.values().min().unwrap();
    println!("most_common - least_common: {}", most_common - least_common);
}

fn polymerize(polymer_template: String, pair_insertion_rules: &HashMap<String, String>) -> String {
    let mut next_polymer =
        String::from_iter(polymer_template.chars().tuple_windows().flat_map(|(a, b)| {
            let pair: String = String::from_iter([a, b]);
            [
                a.to_string(),
                pair_insertion_rules.get(&pair).unwrap().clone(),
            ]
        }));
    let last_char = polymer_template.chars().rev().next().unwrap();
    next_polymer.push_str(&last_char.to_string());
    next_polymer
}

fn char_counts(s: &str) -> HashMap<char, usize> {
    let mut counts = HashMap::new();
    for c in s.chars() {
        let count = counts.entry(c).or_insert(0);
        *count += 1;
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

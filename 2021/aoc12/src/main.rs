use std::collections::HashMap;
use std::fs::File;
use std::io::{BufRead, BufReader};

#[derive(Debug)]
struct CaveNetwork {
    adj_list: HashMap<String, Vec<String>>,
}

impl CaveNetwork {
    fn new(edges: Vec<(String, String)>) -> CaveNetwork {
        let mut adj_list: HashMap<String, Vec<String>> = HashMap::new();

        for (a, b) in edges {
            let traversable_from_a = adj_list.entry(a.clone()).or_default();
            traversable_from_a.push(b.clone());
            let traversable_from_b = adj_list.entry(b).or_default();
            traversable_from_b.push(a);
        }

        CaveNetwork { adj_list }
    }

    fn explore_all_paths(&self) -> Vec<Vec<String>> {
        let mut paths_to_end = vec![];
        self.explore_all_paths_helper(
            "start".to_string(),
            vec![],
            HashMap::new(),
            &mut paths_to_end,
        );
        paths_to_end
    }

    fn explore_all_paths_helper(
        &self,
        curr_cave: String,
        mut curr_path: Vec<String>,
        mut visited_small_caves: HashMap<String, u8>,
        paths_to_end: &mut Vec<Vec<String>>,
    ) {
        // println!("curr_path: {:?}, curr_cave: {:?}", curr_path, curr_cave);
        curr_path.push(curr_cave.clone());
        if curr_cave == "end" {
            paths_to_end.push(curr_path);
        } else {
            // not the end KEEP SEARCHING

            let visited = visited_small_caves.contains_key(&curr_cave);
            let visited_once = visited_small_caves
                .get(&curr_cave)
                .map_or_else(|| false, |n| n == &1);
            let small_cave_visited_twice = visited_small_caves.values().any(|n| n == &2);

            if !visited || (visited_once && !small_cave_visited_twice && curr_cave != "start") {
                if !curr_cave.chars().next().unwrap().is_uppercase() {
                    // small caves can only be searched once
                    let cave_visits = visited_small_caves.entry(curr_cave.clone()).or_insert(0);
                    *cave_visits += 1;
                }

                // copy current path and branch out from here
                let maybe_neighbor_caves = self.adj_list.get(&curr_cave);
                if let Some(neighbor_caves) = maybe_neighbor_caves {
                    for neighbor in neighbor_caves {
                        self.explore_all_paths_helper(
                            neighbor.clone(),
                            curr_path.clone(),
                            visited_small_caves.clone(),
                            paths_to_end,
                        );
                    }
                }
            }
        }
    }
}

fn main() {
    let filename = "input/input.txt";
    let cave: CaveNetwork = parse_input_file(filename);

    println!("cave: {:?}", cave);
    println!();

    let paths = cave.explore_all_paths();
    // println!("all paths through cave:");
    // println!("{:?}", paths);
    println!("num paths through cave: {}", paths.len());
}

fn parse_input_file(filename: &str) -> CaveNetwork {
    // Open the file in read-only mode (ignoring errors).
    let file = File::open(filename).expect("couldn't open file");
    let reader = BufReader::new(file);

    // Read the file line by line using the lines() iterator from std::io::BufRead.
    let edges: Vec<(String, String)> = reader
        .lines()
        .map(|l| {
            let line = l.unwrap();
            let parts: Vec<&str> = line.split('-').collect();
            assert_eq!(parts.len(), 2);
            (parts[0].to_string(), parts[1].to_string())
        })
        .collect();

    CaveNetwork::new(edges)
}

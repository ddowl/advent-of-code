use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
use std::fs;

type Coordinate = (usize, usize);

#[derive(Copy, Clone, Eq, PartialEq)]
struct State {
    cost: usize,
    coord: Coordinate,
}

// The priority queue depends on `Ord`.
// Explicitly implement the trait so the queue becomes a min-heap
// instead of a max-heap.
impl Ord for State {
    fn cmp(&self, other: &Self) -> Ordering {
        // Notice that the we flip the ordering on costs.
        // In case of a tie we compare positions - this step is necessary
        // to make implementations of `PartialEq` and `Ord` consistent.
        other
            .cost
            .cmp(&self.cost)
            .then_with(|| self.coord.cmp(&other.coord))
    }
}

// `PartialOrd` needs to be implemented as well.
impl PartialOrd for State {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

fn main() {
    let filename = "input/input.txt";
    let risk_levels = parse_input_file(filename);

    println!("risk_levels: {:?}", risk_levels);
    println!();

    let cavern_len = risk_levels.len();
    let cost_to_exit = shortest_path_cost(&risk_levels, (0, 0), (cavern_len - 1, cavern_len - 1));
    println!("cost_to_exit: {:?}", cost_to_exit);
}

fn shortest_path_cost(
    risk_levels: &Vec<Vec<u8>>,
    start_coord: Coordinate,
    dest_coord: Coordinate,
) -> Option<usize> {
    let cavern_len = risk_levels.len();

    // add all coordinates to the vertex priority queue
    let mut unvisited_vertex_heap = BinaryHeap::new();

    // nodes not present are an infinite distance away
    let mut tentative_distances: HashMap<Coordinate, usize> = HashMap::new();
    tentative_distances.insert(start_coord, 0);

    unvisited_vertex_heap.push(State {
        cost: 0,
        coord: start_coord,
    });

    // Examine the frontier with lower cost nodes first (min-heap)
    while let Some(State { cost, coord }) = unvisited_vertex_heap.pop() {
        // Alternatively we could have continued to find all shortest paths
        if coord == dest_coord {
            return Some(cost);
        }

        // Important as we may have already found a better way
        if cost > *tentative_distances.get(&coord).unwrap_or(&usize::MAX) {
            continue;
        }

        // For each node we can reach, see if we can find a way with
        // a lower cost going through this node
        for unvisited_neighbor in grid_neighbors(coord, cavern_len) {
            let (x, y) = unvisited_neighbor;
            let next = State {
                cost: cost + <usize>::from(risk_levels[x][y]),
                coord: unvisited_neighbor,
            };

            // If so, add it to the frontier and continue
            if next.cost < *tentative_distances.get(&next.coord).unwrap_or(&usize::MAX) {
                unvisited_vertex_heap.push(next);
                // Relaxation, we have now found a better way
                tentative_distances.insert(next.coord, next.cost);
            }
        }
    }

    // Goal not reachable
    None
}

fn grid_neighbors((x, y): Coordinate, side_len: usize) -> Vec<Coordinate> {
    let ix: isize = x.try_into().unwrap();
    let iy: isize = y.try_into().unwrap();
    let iside_len: isize = side_len.try_into().unwrap();

    let in_bounds = |n: isize| n >= 0 && n < iside_len;

    vec![(ix + 1, iy), (ix - 1, iy), (ix, iy + 1), (ix, iy - 1)]
        .into_iter()
        .filter(|(cx, cy)| in_bounds(*cx) && in_bounds(*cy))
        .map(|(cx, cy)| (cx.try_into().unwrap(), cy.try_into().unwrap()))
        .collect()
}

fn parse_input_file(filename: &str) -> Vec<Vec<u8>> {
    let file_contents = fs::read_to_string(filename).unwrap();
    file_contents
        .split('\n')
        .map(|l| {
            l.chars()
                .map(|s| s.to_digit(10).unwrap().try_into().unwrap())
                .collect()
        })
        .collect()
}

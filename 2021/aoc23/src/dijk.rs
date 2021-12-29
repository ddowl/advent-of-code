use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
use std::hash::Hash;

#[derive(PartialEq, Eq, Clone, Copy)]
struct NodeCost<T> {
    cost: usize,
    node: T,
}

// `PartialOrd` needs to be implemented as well.
impl<T: Ord + Hash> PartialOrd<Self> for NodeCost<T> {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

// The priority queue depends on `Ord`.
// Explicitly implement the trait so the queue becomes a min-heap
// instead of a max-heap.
impl<T: Ord + Hash> Ord for NodeCost<T> {
    fn cmp(&self, other: &Self) -> Ordering {
        // Notice that the we flip the ordering on costs.
        // In case of a tie we compare positions - this step is necessary
        // to make implementations of `PartialEq` and `Ord` consistent.
        other
            .cost
            .cmp(&self.cost)
            .then_with(|| self.node.cmp(&other.node))
    }
}

type NeighborsFn<N> = dyn Fn(&N) -> Vec<(N, usize)>;
type FinishedFn<T> = dyn Fn(&T) -> bool;

pub(crate) struct Dijkstra<Node> {
    get_neighbors: Box<NeighborsFn<Node>>,
    is_finished: Box<FinishedFn<Node>>,
}

impl<Node: Ord + Hash + Clone> Dijkstra<Node> {
    pub(crate) fn new(
        get_neighbors: Box<NeighborsFn<Node>>,
        is_finished: Box<FinishedFn<Node>>,
    ) -> Self {
        Dijkstra {
            get_neighbors,
            is_finished,
        }
    }

    pub(crate) fn shortest_path(&self, start_node: Node) -> Option<(Vec<(Node, usize)>, usize)> {
        // add all coordinates to the vertex priority queue
        let mut unvisited_vertex_heap = BinaryHeap::new();

        // nodes not present are an infinite distance away
        let mut tentative_distances: HashMap<Node, (Vec<(Node, usize)>, usize)> = HashMap::new();
        tentative_distances.insert(start_node.clone(), (vec![(start_node.clone(), 0)], 0));

        unvisited_vertex_heap.push(NodeCost {
            cost: 0,
            node: start_node,
        });

        // Examine the frontier with lower cost nodes first (min-heap)
        while let Some(NodeCost { cost, node }) = unvisited_vertex_heap.pop() {
            // Alternatively we could have continued to find all shortest paths
            if (self.is_finished)(&node) {
                return tentative_distances.get(&node).cloned();
            }

            // Important as we may have already found a better way
            if cost
                > *tentative_distances
                    .get(&node)
                    .map(|(_path, cost)| cost)
                    .unwrap_or(&usize::MAX)
            {
                continue;
            }

            let path_so_far = tentative_distances.get(&node).unwrap().0.clone();

            // For each node we can reach, see if we can find a way with
            // a lower cost going through this node
            for (unvisited_neighbor, cost_to_neighbor) in (self.get_neighbors)(&node) {
                let next = NodeCost {
                    cost: cost + cost_to_neighbor,
                    node: unvisited_neighbor.clone(),
                };

                // If so, add it to the frontier and continue
                if next.cost
                    < *tentative_distances
                        .get(&next.node)
                        .map(|(_path, cost)| cost)
                        .unwrap_or(&usize::MAX)
                {
                    unvisited_vertex_heap.push(next.clone());
                    // Relaxation, we have now found a better way
                    let mut path_to_next = path_so_far.clone();
                    path_to_next.push((unvisited_neighbor, cost_to_neighbor));
                    tentative_distances.insert(next.node, (path_to_next, next.cost));
                }
            }
        }

        // Goal not reachable
        None
    }
}

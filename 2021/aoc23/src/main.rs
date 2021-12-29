mod dijk;

use crate::BurrowLocation::{Hallway, Room};
use lazy_static::lazy_static;
use std::cmp::{max, min};
use std::collections::HashMap;
use std::fs;

lazy_static! {
    static ref ORGANIZED_SIDE_ROOMS: [Vec<Amphipod>; 4] = [
        vec![Amphipod::A, Amphipod::A, Amphipod::A, Amphipod::A],
        vec![Amphipod::B, Amphipod::B, Amphipod::B, Amphipod::B],
        vec![Amphipod::C, Amphipod::C, Amphipod::C, Amphipod::C],
        vec![Amphipod::D, Amphipod::D, Amphipod::D, Amphipod::D],
    ];
    static ref STARTING_TEST_SIDE_ROOMS: [Vec<Amphipod>; 4] = [
        vec![Amphipod::A, Amphipod::B],
        vec![Amphipod::D, Amphipod::C],
        vec![Amphipod::C, Amphipod::B],
        vec![Amphipod::A, Amphipod::D],
    ];
    static ref AMPHIPOD_ENERGY_COSTS: HashMap<Amphipod, usize> = HashMap::from([
        (Amphipod::A, 1),
        (Amphipod::B, 10),
        (Amphipod::C, 100),
        (Amphipod::D, 1000)
    ]);
}

const ORGANIZED_AMPHIPOD_ROOMS: [Amphipod; 4] =
    [Amphipod::A, Amphipod::B, Amphipod::C, Amphipod::D];
const VALID_HALLWAY_IDXS: [usize; 7] = [0, 1, 3, 5, 7, 9, 10];

type Position = (isize, isize);

fn manhattan_distance((ax, ay): &Position, (bx, by): &Position) -> usize {
    ((ax - bx).abs() + ay + by) as usize
}

#[derive(PartialEq, Eq, PartialOrd, Ord, Hash, Debug, Clone, Copy)]
enum Amphipod {
    A,
    B,
    C,
    D,
}

#[derive(PartialEq, Eq, PartialOrd, Ord, Hash, Clone, Debug)]
struct Burrow {
    hallways: [Option<Amphipod>; 11],
    // room is stack
    rooms: [Vec<Amphipod>; 4],
    room_size: usize,
}

impl Burrow {
    fn new(rooms: [Vec<Amphipod>; 4]) -> Self {
        let room_size = rooms[0].len();
        Burrow {
            hallways: Default::default(),
            rooms,
            room_size,
        }
    }

    fn apply_move(&self, amphipod_move: &Move) -> Self {
        let mut burrow_clone = self.clone();
        amphipod_move.apply(&mut burrow_clone);
        burrow_clone
    }

    fn is_organized(&self) -> bool {
        // for room_idx in 0..4 {
        //     let expected_amphipod = ORGANIZED_AMPHIPOD_ROOMS[room_idx];
        //     let room = &self.rooms[room_idx];
        //     if room.len() != self.room_size || room.iter().any(|a| a != &expected_amphipod) {
        //         return false;
        //     }
        // }
        // true
        self.rooms[..] == ORGANIZED_SIDE_ROOMS[..]
    }

    fn reachable_hallways(&self, room_idx: usize) -> Vec<usize> {
        let room_hallway_idx = 2 + 2 * room_idx;
        assert!(!VALID_HALLWAY_IDXS.contains(&room_hallway_idx));

        let blocked_left: Option<usize> = (0..room_hallway_idx)
            .rev()
            .find(|i| self.hallways[*i as usize].is_some());
        let blocked_right: Option<usize> =
            ((room_hallway_idx + 1)..11).find(|i| self.hallways[*i as usize].is_some());

        let valid_left = match blocked_left {
            None => 0,
            // will never be blocked passed 7 to the left
            Some(blocked_hallway_idx) => {
                if blocked_hallway_idx == 0 {
                    1
                } else {
                    blocked_hallway_idx + 2
                }
            }
        };

        let valid_right = match blocked_right {
            None => 10,
            // will never be blocked passed 3 to the right
            Some(blocked_hallway_idx) => {
                if blocked_hallway_idx == 10 {
                    9
                } else {
                    blocked_hallway_idx - 2
                }
            }
        };

        VALID_HALLWAY_IDXS
            .iter()
            .filter(|&&i| {
                (i >= valid_left && i < room_hallway_idx)
                    || (i > room_hallway_idx && i <= valid_right)
            })
            .copied()
            .collect()
    }

    fn room_is_organized(&self, room_idx: usize) -> bool {
        let expected_amphipod = ORGANIZED_AMPHIPOD_ROOMS[room_idx];
        let room = self.rooms.get(room_idx).unwrap();
        room.len() == self.room_size && room.iter().all(|a| a == &expected_amphipod)
    }

    fn moves(&self) -> Vec<Move> {
        let mut valid_next_moves: Vec<Move> = vec![];

        for unorganized_room_idx in (0..4).filter(|&i| !self.room_is_organized(i)) {
            let from_location = Room(unorganized_room_idx);
            let unorganized_room = self.rooms.get(unorganized_room_idx).unwrap();
            if let Some(moving_amphipod) = unorganized_room.last() {
                // room to hallway
                let reachable_hallway_idxs = self.reachable_hallways(unorganized_room_idx);
                let hallway_moves: Vec<Move> = reachable_hallway_idxs
                    .iter()
                    .map(|hidx| Move {
                        from: from_location,
                        to: Hallway(*hidx),
                    })
                    .collect();
                valid_next_moves.extend(hallway_moves);

                // room to room
                let destination_room_idx = ORGANIZED_AMPHIPOD_ROOMS
                    .iter()
                    .position(|organized_amph| organized_amph == moving_amphipod)
                    .unwrap();

                // if you're in the right room, no need to move
                if destination_room_idx == unorganized_room_idx {
                    continue;
                }

                let destination_room = self.rooms.get(destination_room_idx).unwrap();
                // path must not be blocked and destination room must have space and not contain other types of amphipods
                let unorganized_room_hallway_idx = 2 + 2 * unorganized_room_idx;
                let destination_room_hallway_idx = 2 + 2 * destination_room_idx;

                let min_hidx = min(unorganized_room_hallway_idx, destination_room_hallway_idx);
                let max_hidx = max(unorganized_room_hallway_idx, destination_room_hallway_idx);

                let path_to_dest_room_blocked = self
                    .hallways
                    .iter()
                    .enumerate()
                    .filter_map(|(hallway_idx, amph)| amph.map(|_| (hallway_idx)))
                    .any(|hallway_idx| hallway_idx > min_hidx && hallway_idx < max_hidx);

                if !path_to_dest_room_blocked
                    && destination_room.len() < self.room_size
                    && destination_room.iter().all(|a| a == moving_amphipod)
                {
                    valid_next_moves.push(Move {
                        from: from_location,
                        to: Room(destination_room_idx),
                    })
                }
            }
        }

        // hallway to room
        for (current_hallway_idx, moving_amphipod) in self
            .hallways
            .iter()
            .enumerate()
            .filter_map(|(hidx, amph)| amph.map(|a| (hidx, a)))
        {
            let destination_room_idx = ORGANIZED_AMPHIPOD_ROOMS
                .iter()
                .position(|organized_amph| organized_amph == &moving_amphipod)
                .unwrap();

            let destination_room = self.rooms.get(destination_room_idx).unwrap();
            // path must not be blocked and destination room must have space and not contain other types of amphipods
            let destination_room_hallway_idx = 2 + 2 * destination_room_idx;

            let min_hidx = min(current_hallway_idx, destination_room_hallway_idx);
            let max_hidx = max(current_hallway_idx, destination_room_hallway_idx);

            let path_to_dest_room_blocked = self
                .hallways
                .iter()
                .enumerate()
                .filter_map(|(hidx, amph)| amph.map(|_| hidx))
                .any(|hallway_idx| hallway_idx > min_hidx && hallway_idx < max_hidx);

            if !path_to_dest_room_blocked
                && destination_room.len() < self.room_size
                && destination_room.iter().all(|a| a == &moving_amphipod)
            {
                valid_next_moves.push(Move {
                    from: Hallway(current_hallway_idx),
                    to: Room(destination_room_idx),
                })
            }
        }

        valid_next_moves
    }

    fn print(&self) {
        let amph_to_char = |a: &Amphipod| match a {
            Amphipod::A => 'A',
            Amphipod::B => 'B',
            Amphipod::C => 'C',
            Amphipod::D => 'D',
        };

        println!("#############");
        let hallway_str: String = self
            .hallways
            .iter()
            .map(|amph| match amph {
                None => '.',
                Some(a) => amph_to_char(a),
            })
            .collect();
        println!("#{}#", hallway_str);

        let top_slots: Vec<char> = self
            .rooms
            .iter()
            .map(|r| {
                if r.len() < 4 {
                    '.'
                } else {
                    amph_to_char(r.get(3).unwrap())
                }
            })
            .collect();

        let third_slots: Vec<char> = self
            .rooms
            .iter()
            .map(|r| {
                if r.len() < 3 {
                    '.'
                } else {
                    amph_to_char(r.get(2).unwrap())
                }
            })
            .collect();

        let second_slots: Vec<char> = self
            .rooms
            .iter()
            .map(|r| {
                if r.len() < 2 {
                    '.'
                } else {
                    amph_to_char(r.get(1).unwrap())
                }
            })
            .collect();

        let bottom_slots: Vec<char> = self
            .rooms
            .iter()
            .map(|r| {
                if r.is_empty() {
                    '.'
                } else {
                    amph_to_char(r.get(0).unwrap())
                }
            })
            .collect();

        println!(
            "###{}#{}#{}#{}###",
            top_slots[0], top_slots[1], top_slots[2], top_slots[3]
        );
        println!(
            "###{}#{}#{}#{}###",
            third_slots[0], third_slots[1], third_slots[2], third_slots[3]
        );
        println!(
            "###{}#{}#{}#{}###",
            second_slots[0], second_slots[1], second_slots[2], second_slots[3]
        );
        println!(
            "  #{}#{}#{}#{}#",
            bottom_slots[0], bottom_slots[1], bottom_slots[2], bottom_slots[3]
        );
        println!("  #########");
    }
}

#[derive(PartialOrd, Ord, PartialEq, Eq, Hash, Clone, Copy, Debug)]
enum BurrowLocation {
    Hallway(usize),
    Room(usize),
}

impl BurrowLocation {
    fn valid(&self) -> bool {
        match self {
            BurrowLocation::Hallway(i) => ![2, 4, 6, 8].contains(i),
            BurrowLocation::Room(i) => i < &4,
        }
    }

    fn is_open(&self, burrow: &Burrow) -> bool {
        match self {
            BurrowLocation::Hallway(i) => burrow.hallways[*i].is_none(),
            BurrowLocation::Room(i) => burrow.rooms[*i].len() < burrow.room_size,
        }
    }

    fn get_amphipod(&self, burrow: &Burrow) -> Option<Amphipod> {
        match self {
            BurrowLocation::Hallway(i) => burrow.hallways[*i],
            BurrowLocation::Room(i) => burrow.rooms[*i].last().copied(),
        }
    }

    fn position(&self, burrow: &Burrow) -> Position {
        match self {
            BurrowLocation::Hallway(i) => (*i as isize, 0),
            // 0 => 2, 1 => 4, 2 => 6, 3 => 8
            BurrowLocation::Room(i) => (
                (2 + 2 * i) as isize,
                ((burrow.room_size + 1) - burrow.rooms[*i].len()) as isize,
            ),
        }
    }
}

// Note that movement from and to the same Position variant is disallowed.
// E.g. moving from one hallway location to another, since amphipods will only move out of their rooms once before spending their other move going into a room.
#[derive(PartialOrd, Ord, PartialEq, Eq, Hash, Clone, Copy, Debug)]
struct Move {
    from: BurrowLocation,
    to: BurrowLocation,
}

impl Move {
    fn is_valid(&self, burrow: &Burrow) -> bool {
        let hallway_to_hallway = matches!((self.from, self.to), (Hallway(_), Hallway(_)));

        self.from.valid() && self.to.valid() && self.to.is_open(burrow) && !hallway_to_hallway
    }

    fn cost(&self, burrow: &Burrow) -> usize {
        let amphipod = self.from.get_amphipod(burrow).unwrap();
        let from_pos = self.from.position(burrow);
        // let to_pos = self.to.position(burrow);
        let to_pos = match self.to {
            BurrowLocation::Hallway(i) => (i as isize, 0),
            // 0 => 2, 1 => 4, 2 => 6, 3 => 8
            BurrowLocation::Room(i) => (
                (2 + 2 * i) as isize,
                (burrow.room_size - burrow.rooms[i].len()) as isize,
            ),
        };

        AMPHIPOD_ENERGY_COSTS[&amphipod] * manhattan_distance(&from_pos, &to_pos)
    }

    fn apply(&self, burrow: &mut Burrow) {
        if !self.is_valid(burrow) {
            panic!("AAAAAAAAAA");
        }
        let amphipod = match self.from {
            Hallway(i) => {
                let amph = burrow.hallways[i];
                burrow.hallways[i] = None;
                amph
            }
            Room(i) => burrow.rooms.get_mut(i).unwrap().pop(),
        }
        .unwrap();

        match self.to {
            Hallway(i) => {
                assert!(burrow.hallways[i].is_none());
                burrow.hallways[i] = Some(amphipod);
            }
            Room(i) => burrow.rooms.get_mut(i).unwrap().push(amphipod),
        };
    }
}

fn main() {
    let filename = "input/part2_input.txt";
    let rooms = parse_input_file(filename);

    let burrow = Burrow::new(rooms);
    println!("burrow: {:?}", burrow);
    println!();

    let get_neighbors = |burrow: &Burrow| {
        // burrow.print();
        // println!();
        burrow
            .moves()
            .iter()
            .map(|mv| {
                // println!("move: {:?}", mv);
                (burrow.apply_move(mv), mv.cost(burrow))
            })
            .collect()
    };

    let is_finished = |burrow: &Burrow| burrow.is_organized();

    let dijkstra_solver = dijk::Dijkstra::new(Box::new(get_neighbors), Box::new(is_finished));

    if let Some((path, cost)) = dijkstra_solver.shortest_path(burrow) {
        println!("cost: {:?}", cost);
        for (b, bc) in path {
            b.print();
            println!("cost to move: {}", bc);
            println!();
        }
    } else {
        println!("not solvable");
    }
}

fn parse_input_file(filename: &str) -> [Vec<Amphipod>; 4] {
    let file_contents = fs::read_to_string(filename).unwrap();
    let amphipod_strs: Vec<_> = file_contents
        .split('\n')
        .skip(2)
        .take(4)
        .map(|l| {
            (3..=9)
                .step_by(2)
                .map(|n| match &l[n..=n] {
                    "A" => Amphipod::A,
                    "B" => Amphipod::B,
                    "C" => Amphipod::C,
                    "D" => Amphipod::D,
                    x => panic!("unknown amphipod: {}", x),
                })
                .collect::<Vec<_>>()
        })
        .collect();

    assert_eq!(amphipod_strs.len(), 4);
    assert_eq!(amphipod_strs.get(0).unwrap().len(), 4);
    assert_eq!(amphipod_strs.get(1).unwrap().len(), 4);

    let ts = &amphipod_strs[0];
    let bs = &amphipod_strs[1];

    [
        vec![
            amphipod_strs[3][0],
            amphipod_strs[2][0],
            amphipod_strs[1][0],
            amphipod_strs[0][0],
        ],
        vec![
            amphipod_strs[3][1],
            amphipod_strs[2][1],
            amphipod_strs[1][1],
            amphipod_strs[0][1],
        ],
        vec![
            amphipod_strs[3][2],
            amphipod_strs[2][2],
            amphipod_strs[1][2],
            amphipod_strs[0][2],
        ],
        vec![
            amphipod_strs[3][3],
            amphipod_strs[2][3],
            amphipod_strs[1][3],
            amphipod_strs[0][3],
        ],
    ]
}

#[cfg(test)]
mod tests {
    use super::*;

    const EMPTY_HALLWAY: [Option<Amphipod>; 11] = [None; 11];

    #[test]
    fn test_burrow_is_organized() {
        let tests: HashMap<[Vec<Amphipod>; 4], bool> = HashMap::from([
            (STARTING_TEST_SIDE_ROOMS.clone(), false),
            (ORGANIZED_SIDE_ROOMS.clone(), true),
        ]);

        for (rooms, expected_result) in tests {
            let burrow = Burrow::new(rooms);
            assert_eq!(burrow.is_organized(), expected_result);
        }
    }

    #[test]
    fn test_reachable_hallways() {
        // open hallway
        for i in 0..=3 {
            assert_eq!(
                Burrow::new(STARTING_TEST_SIDE_ROOMS.clone()).reachable_hallways(i),
                VALID_HALLWAY_IDXS.to_vec()
            );
        }

        // one hallway occupied in middle
        let mut occupied_middle_hallway = EMPTY_HALLWAY;
        occupied_middle_hallway[5] = Some(Amphipod::B);
        let burrow_with_occupied_middle_hallway = Burrow {
            hallways: occupied_middle_hallway,
            rooms: STARTING_TEST_SIDE_ROOMS.clone(),
            room_size: 2,
        };

        for i in 0..=1 {
            assert_eq!(
                burrow_with_occupied_middle_hallway.reachable_hallways(i),
                [0, 1, 3]
            );
        }
        for i in 2..=3 {
            assert_eq!(
                burrow_with_occupied_middle_hallway.reachable_hallways(i),
                [7, 9, 10]
            );
        }

        // room has no valid hallways
        let mut occupied_hallway_around_first_room = EMPTY_HALLWAY;
        occupied_hallway_around_first_room[1] = Some(Amphipod::A);
        occupied_hallway_around_first_room[3] = Some(Amphipod::A);
        let burrow_with_no_first_room_moves = Burrow {
            hallways: occupied_hallway_around_first_room,
            rooms: STARTING_TEST_SIDE_ROOMS.clone(),
            room_size: 2,
        };
        assert_eq!(burrow_with_no_first_room_moves.reachable_hallways(0), []);
    }

    #[test]
    fn test_generate_moves() {
        let from_rooms_to_hallways: Vec<Move> = (0..4)
            .flat_map(|ri| {
                VALID_HALLWAY_IDXS
                    .iter()
                    .map(|hi| Move {
                        from: Room(ri),
                        to: Hallway(*hi),
                    })
                    .collect::<Vec<_>>()
            })
            .collect();
        let tests = HashMap::from([(STARTING_TEST_SIDE_ROOMS.clone(), from_rooms_to_hallways)]);

        for (rooms, expected_moves) in tests {
            let burrow = Burrow::new(rooms);
            assert_eq!(burrow.moves(), expected_moves);
        }
    }
}

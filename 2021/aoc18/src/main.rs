use crate::SnailfishNumber::*;
use itertools::Itertools;
use std::cmp::max;
use std::fs;

#[derive(PartialEq, Eq, Debug, Hash)]
enum SnailfishNumber {
    Literal(u8),
    Pair(Box<SnailfishNumber>, Box<SnailfishNumber>),
}

impl SnailfishNumber {
    fn new_pair(left: SnailfishNumber, right: SnailfishNumber) -> Self {
        Pair(Box::new(left), Box::new(right))
    }

    fn parse(s: &str) -> (Self, usize) {
        if &s[0..1] == "[" {
            // parse pair
            let (left, left_num_chars_read) = SnailfishNumber::parse(&s[1..]);
            let (right, right_num_chars_read) =
                SnailfishNumber::parse(&s[((left_num_chars_read + 2)..)]); // + 2 for left bracket and comma
            (
                SnailfishNumber::new_pair(left, right),
                left_num_chars_read + right_num_chars_read + 3, // + 3 for brackets and comma
            )
        } else {
            (Literal(s[0..1].parse().unwrap()), 1)
        }
    }

    fn magnitude(&self) -> usize {
        match self {
            Literal(v) => (*v).into(),
            Pair(left, right) => 3 * left.magnitude() + 2 * right.magnitude(),
        }
    }

    fn add(self, other: SnailfishNumber) -> Self {
        SnailfishNumber::new_pair(self, other).reduce()
    }

    fn reduce(self) -> Self {
        let mut curr = self;
        let mut action_occurred = true;
        while action_occurred {
            action_occurred = false;

            let (exploded, maybe_exploded) = curr.explode(0);
            curr = exploded;
            if let Some(_) = maybe_exploded {
                action_occurred = true;
            } else {
                let (split, did_split) = curr.split();
                curr = split;
                if did_split {
                    action_occurred = true;
                }
            }
        }
        curr
    }

    fn explode(self, depth: usize) -> (Self, Option<(Option<u8>, Option<u8>)>) {
        match self {
            Pair(left, right) => {
                if let (Literal(lv), Literal(rv), 4) = (left.as_ref(), right.as_ref(), depth) {
                    // explode this, propagate values up tree to be added elsewhere
                    return (Literal(0), Some((Some(*lv), Some(*rv))));
                }

                // explode left then right pair, shortcutting if left explodes first.
                // If left explodes, attempt to send right value to right pair, if exists
                // If right explodes, attempt to send left value to left pair, if exists

                let exploded_left = if let Pair(_, _) = left.as_ref() {
                    let (exploded_left, exploded_vals) = left.explode(depth + 1);
                    if let Some((l_opt, r_opt)) = exploded_vals {
                        // your left pair exploded!
                        // if the right value is present, add it to the leftmost number in your right pair, and send up None in its place.
                        // otherwise, send up both values

                        let (r_opt, right) = match r_opt {
                            None => (r_opt, right),
                            Some(rv) => (None, Box::new(right.add_to_leftmost_literal(rv))),
                        };

                        return (Pair(Box::new(exploded_left), right), Some((l_opt, r_opt)));
                    }
                    Box::new(exploded_left)
                } else {
                    left
                };

                let exploded_right = if let Pair(_, _) = right.as_ref() {
                    let (exploded_right, exploded_vals) = right.explode(depth + 1);
                    if let Some((l_opt, r_opt)) = exploded_vals {
                        // your right pair exploded!
                        // if the left value is present, add it to the rightmost number in your left pair, and send up None in its place.
                        // otherwise, send up both values

                        let (l_opt, left) = match l_opt {
                            None => (l_opt, exploded_left),
                            Some(lv) => {
                                (None, Box::new(exploded_left.add_to_rightmost_literal(lv)))
                            }
                        };

                        return (Pair(left, Box::new(exploded_right)), Some((l_opt, r_opt)));
                    }
                    Box::new(exploded_right)
                } else {
                    right
                };

                (Pair(exploded_left, exploded_right), None)
            }
            // we shouldn't even traverse to literals
            _ => panic!("wtf we exploded a literal"),
        }
    }

    fn add_to_leftmost_literal(self, val: u8) -> Self {
        match self {
            Literal(n) => Literal(n + val),
            Pair(left, right) => Pair(Box::new(left.add_to_leftmost_literal(val)), right),
        }
    }

    fn add_to_rightmost_literal(self, val: u8) -> Self {
        match self {
            Literal(n) => Literal(n + val),
            Pair(left, right) => Pair(left, Box::new(right.add_to_rightmost_literal(val))),
        }
    }

    fn split(self) -> (Self, bool) {
        match self {
            Literal(v) => {
                if v >= 10 {
                    let (div, rem) = (v / 2, v % 2);
                    (
                        SnailfishNumber::new_pair(Literal(div), Literal(div + rem)),
                        true,
                    )
                } else {
                    (self, false)
                }
            }
            Pair(left, right) => {
                let (split_left, did_split) = left.split();
                let left = Box::new(split_left);
                if did_split {
                    return (Pair(left, right), true);
                }
                let (split_right, did_split) = right.split();
                let right = Box::new(split_right);
                (Pair(left, right), did_split)
            }
        }
    }
}

impl Clone for SnailfishNumber {
    fn clone(&self) -> Self {
        match self {
            Literal(v) => Literal(*v),
            Pair(left, right) => Pair(left.clone(), right.clone()),
        }
    }
}

fn main() {
    let filename = "input/input.txt";
    let num_strs = parse_input_file(filename);

    println!("num_strs: {:?}", num_strs);
    println!();

    let snailfish_nums: Vec<_> = num_strs
        .into_iter()
        .map(|s| SnailfishNumber::parse(&s).0)
        .collect();
    println!("snailfish_nums: {:?}", snailfish_nums);

    // Part 1
    let sum = snailfish_nums
        .iter()
        .cloned()
        .reduce(|acc, num| acc.add(num))
        .unwrap();
    println!("sum: {:?}", sum);
    println!("magnitude of sum: {}", sum.magnitude());

    // Part 2
    let max_mag = snailfish_nums
        .iter()
        .cartesian_product(snailfish_nums.iter())
        .filter(|(num_a, num_b)| num_a != num_b)
        .map(|(num_a, num_b)| num_a.clone().add(num_b.clone()).magnitude())
        .max()
        .unwrap();

    println!(
        "max magnitude of any sum of 2 distinct snailfish nums: {:?}",
        max_mag
    );
}

fn parse_input_file(filename: &str) -> Vec<String> {
    let file_contents = fs::read_to_string(filename).unwrap();
    file_contents.split("\n").map(|l| l.to_string()).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    #[test]
    fn parse_nums() {
        let tests = HashMap::from([
            ("[1,1]", SnailfishNumber::new_pair(Literal(1), Literal(1))),
            (
                "[[1,2],3]",
                SnailfishNumber::new_pair(
                    SnailfishNumber::new_pair(Literal(1), Literal(2)),
                    Literal(3),
                ),
            ),
            (
                "[9,[8,7]]",
                SnailfishNumber::new_pair(
                    Literal(9),
                    SnailfishNumber::new_pair(Literal(8), Literal(7)),
                ),
            ),
            (
                "[[1,9],[8,5]]",
                SnailfishNumber::new_pair(
                    SnailfishNumber::new_pair(Literal(1), Literal(9)),
                    SnailfishNumber::new_pair(Literal(8), Literal(5)),
                ),
            ),
            (
                "[[[[1,2],[3,4]],[[5,6],[7,8]]],9]",
                SnailfishNumber::new_pair(
                    SnailfishNumber::new_pair(
                        SnailfishNumber::new_pair(
                            SnailfishNumber::new_pair(Literal(1), Literal(2)),
                            SnailfishNumber::new_pair(Literal(3), Literal(4)),
                        ),
                        SnailfishNumber::new_pair(
                            SnailfishNumber::new_pair(Literal(5), Literal(6)),
                            SnailfishNumber::new_pair(Literal(7), Literal(8)),
                        ),
                    ),
                    Literal(9),
                ),
            ),
        ]);
        for (s, exptected_sf_num) in tests {
            let (sf_num, _) = SnailfishNumber::parse(s);
            assert_eq!(sf_num, exptected_sf_num);
        }
    }

    #[test]
    fn explode() {
        let tests = HashMap::from([
            ("[[[[[9,8],1],2],3],4]", "[[[[0,9],2],3],4]"),
            ("[7,[6,[5,[4,[3,2]]]]]", "[7,[6,[5,[7,0]]]]"),
            ("[[6,[5,[4,[3,2]]]],1]", "[[6,[5,[7,0]]],3]"),
            (
                "[[3,[2,[1,[7,3]]]],[6,[5,[4,[3,2]]]]]",
                "[[3,[2,[8,0]]],[9,[5,[4,[3,2]]]]]",
            ),
            (
                "[[3,[2,[8,0]]],[9,[5,[4,[3,2]]]]]",
                "[[3,[2,[8,0]]],[9,[5,[7,0]]]]",
            ),
        ]);

        for (s, after_exploded_str) in tests {
            let (sf_num, _) = SnailfishNumber::parse(s);
            let (exploded_sf_num, _) = sf_num.explode(0);
            let (expected_exploded_num, _) = SnailfishNumber::parse(after_exploded_str);
            assert_eq!(exploded_sf_num, expected_exploded_num);
        }
    }

    #[test]
    fn split() {
        let tests = HashMap::from([
            (
                SnailfishNumber::new_pair(Literal(1), Literal(2)),
                SnailfishNumber::new_pair(Literal(1), Literal(2)),
            ),
            (
                SnailfishNumber::new_pair(Literal(1), Literal(10)),
                SnailfishNumber::new_pair(
                    Literal(1),
                    SnailfishNumber::new_pair(Literal(5), Literal(5)),
                ),
            ),
            (
                SnailfishNumber::new_pair(Literal(1), Literal(11)),
                SnailfishNumber::new_pair(
                    Literal(1),
                    SnailfishNumber::new_pair(Literal(5), Literal(6)),
                ),
            ),
            (
                SnailfishNumber::new_pair(Literal(13), Literal(11)),
                SnailfishNumber::new_pair(
                    SnailfishNumber::new_pair(Literal(6), Literal(7)),
                    Literal(11),
                ),
            ),
        ]);

        for (sf_num, after_split_num) in tests {
            let (split_sf_num, _) = sf_num.split();
            assert_eq!(split_sf_num, after_split_num);
        }
    }

    #[test]
    fn reduce() {
        let tests = HashMap::from([(
            "[[[[[4,3],4],4],[7,[[8,4],9]]],[1,1]]",
            "[[[[0,7],4],[[7,8],[6,0]]],[8,1]]",
        )]);
        for (s, after_reduce_str) in tests {
            let (sf_num, _) = SnailfishNumber::parse(s);
            let reduced_sf_num = sf_num.reduce();
            let (expected_reduced_num, _) = SnailfishNumber::parse(after_reduce_str);
            assert_eq!(reduced_sf_num, expected_reduced_num);
        }
    }

    #[test]
    fn add() {
        let tests = HashMap::from([
            (
                vec!["[1,1]", "[2,2]", "[3,3]", "[4,4]"],
                "[[[[1,1],[2,2]],[3,3]],[4,4]]",
            ),
            (
                vec!["[1,1]", "[2,2]", "[3,3]", "[4,4]", "[5,5]"],
                "[[[[3,0],[5,3]],[4,4]],[5,5]]",
            ),
            (
                vec!["[1,1]", "[2,2]", "[3,3]", "[4,4]", "[5,5]", "[6,6]"],
                "[[[[5,0],[7,4]],[5,5]],[6,6]]",
            ),
            (
                vec![
                    "[[[0,[4,5]],[0,0]],[[[4,5],[2,6]],[9,5]]]",
                    "[7,[[[3,7],[4,3]],[[6,3],[8,8]]]]",
                    "[[2,[[0,8],[3,4]]],[[[6,7],1],[7,[1,6]]]]",
                    "[[[[2,4],7],[6,[0,5]]],[[[6,8],[2,8]],[[2,1],[4,5]]]]",
                    "[7,[5,[[3,8],[1,4]]]]",
                    "[[2,[2,2]],[8,[8,1]]]",
                    "[2,9]",
                    "[1,[[[9,3],9],[[9,0],[0,7]]]]",
                    "[[[5,[7,4]],7],1]",
                    "[[[[4,2],2],6],[8,7]]",
                ],
                "[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]",
            ),
        ]);
        for (num_strs, after_sum_str) in tests {
            let sum = num_strs
                .into_iter()
                .map(|s| SnailfishNumber::parse(s).0)
                .reduce(|acc, num| acc.add(num))
                .unwrap();
            let (expected_sum, _) = SnailfishNumber::parse(after_sum_str);
            assert_eq!(sum, expected_sum);
        }
    }

    #[test]
    fn magnitude() {
        let tests = HashMap::from([
            ("[9,1]", 29),
            ("[[9,1],[1,9]]", 129),
            ("[[1,2],[[3,4],5]]", 143),
            ("[[[[0,7],4],[[7,8],[6,0]]],[8,1]]", 1384),
            ("[[[[1,1],[2,2]],[3,3]],[4,4]]", 445),
            ("[[[[3,0],[5,3]],[4,4]],[5,5]]", 791),
            ("[[[[5,0],[7,4]],[5,5]],[6,6]]", 1137),
            (
                "[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]",
                3488,
            ),
        ]);
        for (s, expected_mag) in tests {
            let (sf_num, _) = SnailfishNumber::parse(s);
            let mag = sf_num.magnitude();
            assert_eq!(mag, expected_mag);
        }
    }
}

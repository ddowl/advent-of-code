use std::fs;

type InfiniteImg = (Vec<Vec<char>>, bool);

fn main() {
    let filename = "input/input.txt";
    let (enhancement_algorithm, img) = parse_input_file(filename);
    let enhancement_algo_slice = enhancement_algorithm.as_slice();

    // println!("enhancement_algorithm: {:?}", enhancement_algorithm);
    // println!("img: {:?}", img);
    // println!();

    let mut inf_img: InfiniteImg = (img, false);
    let num_enhance_times = 50;
    for _ in 0..num_enhance_times {
        inf_img = enhance(inf_img, enhancement_algo_slice);
    }

    // println!("inf_img: {:?}", inf_img);
    pretty(&inf_img.0);
    let num_lit_pixels: usize = inf_img
        .0
        .iter()
        .map(|row| {
            row.iter()
                .map(|c| if *c == '#' { 1 } else { 0 })
                .sum::<usize>()
        })
        .sum();
    println!("num_lit_pixels: {}", num_lit_pixels);
}

fn pretty(img: &Vec<Vec<char>>) {
    for row in img {
        println!("{}", row.iter().collect::<String>());
    }
    println!();
}

fn enhance(
    (img, out_of_bounds_is_set): InfiniteImg,
    enhancement_algorithm: &[char],
) -> InfiniteImg {
    let img_size = img.len();
    let iimg_size: isize = img_size.try_into().unwrap();
    let output_img_size = img_size + 2;
    let ioutput_img_size = output_img_size.try_into().unwrap();

    let is_in_bounds = |(x, y): (isize, isize)| x >= 0 && x < iimg_size && y >= 0 && y < iimg_size;

    let to_input_img_idx = |(x, y): (isize, isize)| (x - 1, y - 1);

    let output_img: Vec<Vec<char>> = (0..ioutput_img_size)
        .map(|x: isize| {
            (0..ioutput_img_size)
                .map(|y: isize| {
                    let pixels_around = [
                        (x - 1, y - 1),
                        (x - 1, y),
                        (x - 1, y + 1),
                        (x, y - 1),
                        (x, y),
                        (x, y + 1),
                        (x + 1, y - 1),
                        (x + 1, y),
                        (x + 1, y + 1),
                    ];

                    let serialized_pixels: String = pixels_around
                        .into_iter()
                        .map(to_input_img_idx)
                        .map(|input_img_idx| {
                            if !is_in_bounds(input_img_idx) {
                                match out_of_bounds_is_set {
                                    true => '#',
                                    false => '.',
                                }
                            } else {
                                let (ix, iy) = input_img_idx;
                                let ux: usize = ix.try_into().unwrap();
                                let uy: usize = iy.try_into().unwrap();
                                img[ux][uy]
                            }
                        })
                        .collect();
                    // println!("serialized_pixels: {:?}", serialized_pixels);

                    enhancement_algorithm[enhancement_algorithm_idx(&serialized_pixels)]
                })
                .collect()
        })
        .collect();

    (
        output_img,
        (enhancement_algorithm[0] == '#') ^ out_of_bounds_is_set,
    )
}

fn parse_input_file(filename: &str) -> (Vec<char>, Vec<Vec<char>>) {
    let file_contents = fs::read_to_string(filename).unwrap();
    let parts: Vec<String> = file_contents.split("\n\n").map(|s| s.to_string()).collect();

    let enhancement_code = parts[0].chars().collect();

    let img: Vec<Vec<char>> = parse_img_str(&parts[1]);

    (enhancement_code, img)
}

fn parse_img_str(img_str: &str) -> Vec<Vec<char>> {
    img_str.split('\n').map(|l| l.chars().collect()).collect()
}

fn enhancement_algorithm_idx(pixels: &str) -> usize {
    let binary_string: String = pixels
        .chars()
        .map(|c| if c == '#' { '1' } else { '0' })
        .collect();
    usize::from_str_radix(binary_string.as_str(), 2).unwrap()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_image_enhancement_algorithm_idx() {
        let idx = enhancement_algorithm_idx("...#...#.");
        assert_eq!(idx, 34);
    }

    #[test]
    fn test_enhance() {
        let enhancement = "..#.#..#####.#.#.#.###.##.....###.##.#..###.####..#####..#....#..#..##..###..######.###...####..#..#####..##..#.#####...##.#.#..#.##..#.#......#.###.######.###.####...#.##.##..#..#..#####.....#.#....###..#.##......#.....#..#..#..##..#...##.######.####.####.#.#...#.......#..#.#.#...####.##.#......#..#...##.#.##..#...##.#.##..###.#......#.#.......#.#.#.####.###.##...#.....####.#..#..#.##.#....##..#.####....##...##..#...#......#.#.......#.......##..####..#...#.#.#...##..#.#..###..#####........#..####......#..#";

        let input_str = "#..#.
#....
##..#
..#..
..###";

        let expected_output_str = ".##.##.
#..#.#.
##.#..#
####..#
.#..##.
..##..#
...#.#.";

        let input_img: InfiniteImg = (parse_img_str(input_str), false);
        let expected_output_img: InfiniteImg = (parse_img_str(expected_output_str), false);

        let actual_output_img = enhance(
            input_img,
            enhancement.chars().collect::<Vec<char>>().as_slice(),
        );
        assert_eq!(actual_output_img, expected_output_img);
    }
}

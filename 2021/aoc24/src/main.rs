use lazy_static::lazy_static;
use std::collections::HashMap;
use std::fs;

lazy_static! {
    static ref REGISTER_INDEXS: HashMap<char, usize> =
        HashMap::from([('w', 0), ('x', 1), ('y', 2), ('z', 3)]);
}

#[derive(Debug, Clone, Copy)]
enum Operand {
    Value(isize),
    Register(usize),
}

#[derive(Debug, Clone, Copy)]
enum Instruction {
    // Input reads one digit at a time
    Input(usize),
    Add(usize, Operand),
    Mul(usize, Operand),
    Div(usize, Operand),
    Mod(usize, Operand),
    Equal(usize, Operand),
}

struct ALU {
    registers: [isize; 4],
    program: Vec<Instruction>,
}

impl ALU {
    fn new() -> Self {
        ALU {
            registers: [0; 4],
            program: vec![],
        }
    }

    fn with_program(mut self, program: Vec<Instruction>) -> Self {
        self.program = program;
        self
    }

    fn clear_registers(&mut self) {
        self.registers = [0; 4];
    }

    fn run(&mut self, input_ints: Vec<isize>) -> [isize; 4] {
        // println!("running program on: {:?}", input_ints);

        let mut input_stream = input_ints.into_iter();

        // let input_str = input_int.to_string();
        // let mut digit_stream = input_str.chars().map(|d| d.to_digit(10).unwrap());

        for instr in self.program.clone().iter().copied() {
            match instr {
                Instruction::Input(reg_idx) => {
                    let next_digit = input_stream.next();
                    // println!("next_digit: {:?}", next_digit);
                    self.registers[reg_idx] = next_digit.unwrap();
                }
                Instruction::Add(reg_idx, operand) => {
                    self.op_and_store(reg_idx, operand, |a, b| a + b);
                }
                Instruction::Mul(reg_idx, operand) => {
                    self.op_and_store(reg_idx, operand, |a, b| a * b);
                }
                Instruction::Div(reg_idx, operand) => {
                    self.op_and_store(reg_idx, operand, |a, b| a / b);
                }
                Instruction::Mod(reg_idx, operand) => {
                    self.op_and_store(reg_idx, operand, |a, b| a % b);
                }
                Instruction::Equal(reg_idx, operand) => {
                    self.op_and_store(reg_idx, operand, |a, b| if a == b { 1 } else { 0 });
                }
            }
        }

        let registers_clone = self.registers;
        self.clear_registers();
        registers_clone
    }

    fn op_and_store(
        &mut self,
        reg_idx: usize,
        operand: Operand,
        op: impl Fn(isize, isize) -> isize,
    ) {
        let reg_value = self.registers[reg_idx];
        let operand_value = match operand {
            Operand::Value(v) => v,
            Operand::Register(ri) => self.registers[ri],
        };

        self.registers[reg_idx] = op(reg_value, operand_value)
    }
}

fn main() {
    let filename = "input/input.txt";
    let program = parse_input_file(filename);

    println!("program: {:?}", program);
    println!();

    let mut alu = ALU::new().with_program(program);

    for candidate_model_num in (0..=99999999999999_usize).rev() {
        let digits: Vec<isize> = candidate_model_num
            .to_string()
            .chars()
            .map(|d| d.to_digit(10).unwrap() as isize)
            .collect();

        if digits.contains(&0) {
            continue;
        }

        let result = alu.run(digits);

        // println!("{}: {:?}", candidate_model_num, result);

        if result[3] == 0 {
            println!("MONAD model number is valid");
            println!("candidate_model_num: {}", candidate_model_num);
            println!("result: {:?}", result);
            break;
        }
    }
}

fn parse_input_file(filename: &str) -> Vec<Instruction> {
    let file_contents = fs::read_to_string(filename).unwrap();
    parse_alu_program(file_contents)
}

fn parse_alu_program(program_str: String) -> Vec<Instruction> {
    program_str
        .split('\n')
        .map(|l| {
            let tokens: Vec<&str> = l.split_whitespace().collect();
            let instr_name = tokens[0];
            let first_operand = tokens[1].chars().next().unwrap();
            let first_register = REGISTER_INDEXS[&first_operand];
            match instr_name {
                "inp" => Instruction::Input(first_register),
                "add" => Instruction::Add(first_register, parse_second_operand(tokens[2])),
                "mul" => Instruction::Mul(first_register, parse_second_operand(tokens[2])),
                "div" => Instruction::Div(first_register, parse_second_operand(tokens[2])),
                "mod" => Instruction::Mod(first_register, parse_second_operand(tokens[2])),
                "eql" => Instruction::Equal(first_register, parse_second_operand(tokens[2])),
                instr => panic!("unexpected instruction: {}", instr),
            }
        })
        .collect()
}

fn parse_second_operand(operand_str: &str) -> Operand {
    if let Ok(v) = operand_str.parse::<isize>() {
        Operand::Value(v)
    } else {
        Operand::Register(REGISTER_INDEXS[&operand_str.chars().next().unwrap()])
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn alu() {
        let negate_program = "inp x
mul x -1";
        let three_times_larger_program = "inp z
inp x
mul z 3
eql z x";
        let to_binary_program = "inp w
add z w
mod z 2
div w 2
add y w
mod y 2
div w 2
add x w
mod x 2
div w 2
mod w 2";

        let tests = HashMap::from([
            (
                negate_program,
                vec![(vec![1], [0, -1, 0, 0]), (vec![4], [0, -4, 0, 0])],
            ),
            (
                three_times_larger_program,
                vec![
                    (vec![2, 1], [0, 1, 0, 0]),
                    (vec![2, 2], [0, 2, 0, 0]),
                    (vec![2, 4], [0, 4, 0, 0]),
                    (vec![2, 6], [0, 6, 0, 1]),
                ],
            ),
            (
                to_binary_program,
                vec![
                    (vec![1], [0, 0, 0, 1]),
                    (vec![2], [0, 0, 1, 0]),
                    (vec![4], [0, 1, 0, 0]),
                    (vec![8], [1, 0, 0, 0]),
                    (vec![7], [0, 1, 1, 1]),
                    (vec![15], [1, 1, 1, 1]),
                ],
            ),
        ]);
        for (program_str, ps) in tests {
            let program = parse_alu_program(program_str.to_string());
            let mut alu = ALU::new().with_program(program);
            for (inputs, expected_result) in ps {
                let result = alu.run(inputs);
                assert_eq!(result, expected_result);
            }
        }
    }
}

use crate::LengthType::*;
use crate::PacketPayload::*;
use std::fs;

#[derive(Eq, PartialEq, Debug)]
enum LengthType {
    TotalBitLength(usize),
    NumSubPackets(usize),
}

#[derive(Eq, PartialEq, Debug)]
enum PacketPayload {
    Literal(usize),
    Operator {
        length_type: LengthType,
        sub_packets: Vec<Packet>,
    },
}

#[derive(Eq, PartialEq, Debug)]
struct Packet {
    version: u8,
    type_id: u8,
    payload: PacketPayload,
}

impl Packet {
    fn parse(binary_str: &str) -> (Packet, usize) {
        let version = <u8>::from_str_radix(&binary_str[0..3], 2).unwrap();
        let type_id = <u8>::from_str_radix(&binary_str[3..6], 2).unwrap();

        let payload_fn = if type_id == 4 {
            Packet::parse_literal_payload
        } else {
            Packet::parse_operator_payload
        };
        let (payload, num_bits_read) = payload_fn(&binary_str[6..]);

        (
            Packet {
                version,
                type_id,
                payload,
            },
            6 + num_bits_read,
        )
    }

    fn parse_literal_payload(literal_payload_str: &str) -> (PacketPayload, usize) {
        // look at 5 char chunks, first char is sentinel, extract last 4 digits
        let mut payload_bits: Vec<u8> = vec![];
        let mut num_bits_read = 0;
        for payload_chunk in literal_payload_str.as_bytes().chunks(5) {
            num_bits_read += 5;
            for payload_bit in &payload_chunk[1..] {
                payload_bits.push(*payload_bit);
            }

            if payload_chunk[0] == ('0' as u8) {
                break;
            }
        }

        let payload_value_str: String = payload_bits.into_iter().map(|b| b as char).collect();
        let payload_value = usize::from_str_radix(&payload_value_str, 2).unwrap();

        (Literal(payload_value), num_bits_read)
    }

    fn parse_operator_payload(operator_payload_str: &str) -> (PacketPayload, usize) {
        let first_bit = operator_payload_str.chars().nth(0).unwrap();
        let (length_type_fn, sub_packet_offset): (fn(usize) -> LengthType, usize) =
            if first_bit == '0' {
                (TotalBitLength, 16)
            } else {
                (NumSubPackets, 12)
            };

        let length_val =
            usize::from_str_radix(&operator_payload_str[1..sub_packet_offset], 2).unwrap();
        let length_type = length_type_fn(length_val);

        let mut num_packet_bits_read = 0;
        let mut sub_packets: Vec<Packet> = vec![];

        while match &length_type {
            TotalBitLength(sub_packet_bits_len) => {
                // continue parsing packets until we've parsed sub_packets_len or more
                num_packet_bits_read < *sub_packet_bits_len
            }
            NumSubPackets(num_sub_packets) => {
                // continue parsing until num_sub_packets have been parsed_packet
                sub_packets.len() < *num_sub_packets
            }
        } {
            let (sub_packet, bits_read) =
                Packet::parse(&operator_payload_str[(num_packet_bits_read + sub_packet_offset)..]);
            sub_packets.push(sub_packet);
            num_packet_bits_read += bits_read;
        }

        (
            Operator {
                length_type,
                sub_packets,
            },
            sub_packet_offset + num_packet_bits_read,
        )
    }

    fn versions(&self) -> Vec<u8> {
        match &self.payload {
            Literal(_) => vec![self.version],
            Operator {
                length_type: _,
                sub_packets,
            } => {
                let mut versions = vec![self.version];
                for sub_packet in sub_packets {
                    versions.append(&mut sub_packet.versions());
                }
                versions
            }
        }
    }
}

fn to_binary_str(hex_str: String) -> String {
    hex_str
        .chars()
        .map(|hex_digit| format!("{:04b}", hex_digit.to_digit(16).unwrap()))
        .collect()
}

fn parse_input_file(filename: &str) -> Vec<String> {
    let file_contents = fs::read_to_string(filename).unwrap();
    file_contents.split('\n').map(|s| s.to_string()).collect()
}

fn main() {
    let filename = "input/input.txt";
    let bits_transmissions = parse_input_file(filename);

    println!("bits_transmissions: {:?}", bits_transmissions);
    println!();

    for bit_transmission in bits_transmissions {
        println!("processing transmission '{}'...", bit_transmission);
        let binary_str = to_binary_str(bit_transmission.to_string());
        let (parsed_packet, _) = Packet::parse(&binary_str);
        let version_sum: usize = parsed_packet
            .versions()
            .into_iter()
            .map(|n| usize::from(n))
            .sum();
        println!("sum of packet versions: {}", version_sum);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    #[test]
    fn hex_to_binary_conversion() {
        let tests = HashMap::from([
            ("D2FE28", "110100101111111000101000"),
            (
                "38006F45291200",
                "00111000000000000110111101000101001010010001001000000000",
            ),
            (
                "EE00D40C823060",
                "11101110000000001101010000001100100000100011000001100000",
            ),
        ]);
        for (hex, bin) in tests {
            let binary_str = to_binary_str(hex.to_string());
            assert_eq!(binary_str, bin);
        }
    }

    #[test]
    fn parse_literal_packet() {
        let literal_packet_binary = "110100101111111000101000";
        let (parsed_packet, num_bits_read) = Packet::parse(literal_packet_binary);
        let expected_packet = Packet {
            version: 6,
            type_id: 4,
            payload: Literal(2021),
        };
        assert_eq!(parsed_packet, expected_packet);
        assert_eq!(num_bits_read, literal_packet_binary.len() - 3);
    }

    #[test]
    fn parse_operator_packet() {
        let tests = HashMap::from([
            (
                "38006F45291200",
                (
                    Packet {
                        version: 1,
                        type_id: 6,
                        payload: Operator {
                            length_type: TotalBitLength(27),
                            sub_packets: vec![
                                Packet {
                                    version: 6,
                                    type_id: 4,
                                    payload: Literal(10),
                                },
                                Packet {
                                    version: 2,
                                    type_id: 4,
                                    payload: Literal(20),
                                },
                            ],
                        },
                    },
                    49,
                ),
            ),
            (
                "EE00D40C823060",
                (
                    Packet {
                        version: 7,
                        type_id: 3,
                        payload: Operator {
                            length_type: NumSubPackets(3),
                            sub_packets: vec![
                                Packet {
                                    version: 2,
                                    type_id: 4,
                                    payload: Literal(1),
                                },
                                Packet {
                                    version: 4,
                                    type_id: 4,
                                    payload: Literal(2),
                                },
                                Packet {
                                    version: 1,
                                    type_id: 4,
                                    payload: Literal(3),
                                },
                            ],
                        },
                    },
                    51,
                ),
            ),
        ]);

        for (hex, (expected_packet, expected_bits_read)) in tests {
            println!("testing parsing '{}' into packets...", hex);
            let binary_str = to_binary_str(hex.to_string());
            let (parsed_packet, num_bits_read) = Packet::parse(&binary_str);
            assert_eq!(parsed_packet, expected_packet);
            assert_eq!(num_bits_read, expected_bits_read);
        }
    }

    #[test]
    fn sum_version_nums() {
        let tests = HashMap::from([
            ("8A004A801A8002F478", 16),
            ("620080001611562C8802118E34", 12),
            ("C0015000016115A2E0802F182340", 23),
            ("A0016C880162017C3686B18A3D4780", 31),
        ]);
        for (hex, expected_version_sum) in tests {
            println!("summing version nums for transmission '{}'...", hex);
            let binary_str = to_binary_str(hex.to_string());
            let (parsed_packet, _) = Packet::parse(&binary_str);
            let version_sum: usize = parsed_packet
                .versions()
                .into_iter()
                .map(|n| usize::from(n))
                .sum();
            assert_eq!(version_sum, expected_version_sum);
        }
    }
}

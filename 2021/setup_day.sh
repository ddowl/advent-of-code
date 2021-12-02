#!/bin/sh

if [ $# != 1 ]; then
  echo "Usage: $(basename "$0") <day-number>" >&2
  exit 1
fi
if [ "$(basename "$PWD")" != "2021" ]; then
  echo "must be run from root of 2021 dir" >&2
  exit 1
fi

name="$(printf "aoc%02d" "$1")"
cargo new --bin "$name"
mkdir "$name/input"

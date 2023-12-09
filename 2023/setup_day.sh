#!/bin/sh

if [ $# != 2 ]; then
  echo "Usage: $(basename "$0") <day-number> <problem-name>" >&2
  exit 1
fi
if [ "$(basename "$PWD")" != "2023" ]; then
  echo "must be run from root of 2023 dir" >&2
  exit 1
fi

DAY_NUM=$1
PROBLEM_NAME=$2

DAY="day-$DAY_NUM"

mkdir "$DAY"
mkdir "$DAY/input"
mkdir "$DAY/pt1"
mkdir "$DAY/pt2"

touch "$DAY/README.txt"
touch "$DAY/input/input.go"
touch "$DAY/input/input.txt"
touch "$DAY/input/test.txt"
touch "$DAY/pt1/$PROBLEM_NAME.go"
touch "$DAY/pt2/$PROBLEM_NAME.go"

cd "$DAY"
go mod init "aoc/$DAY"
cd ..